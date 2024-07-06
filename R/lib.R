## Update fdObj by reading the data from the disk
fd_update = function(fdObj_loc) {
    fdObj_global = as.character(substitute(fdObj, env = parent.frame(n = 1)))
    fdObj_parent = as.character(substitute(fdObj))
    print(fdObj_global)
    lock = lock(file.path(fdObj_loc$dir, "/db.lock"), exclusive = FALSE)
    if (!dir.exists(fdObj_loc$dir)) {
        stop("Directory does not exist")
    }
    env = readr::read_rds(file.path(fdObj_loc$dir, "env.rds"))
    fdObj_loc$env = env
    unlock(lock)
    assign(fdObj_global, fdObj_loc, envir = parent.frame(n = 2))
    assign(fdObj_parent, fdObj_loc, envir = parent.frame(n = 1))
}

## Save the ggfigdone data to the disk
fd_save = function(fdObj) {
    message("Saving the ggfigdone data to the disk...")
    lock = lock(file.path(fdObj$dir, "/db.lock"), exclusive = TRUE)
    readr::write_rds(fdObj$env, file.path(fdObj$dir, "env.rds"))
    unlock(lock)
}

## Save the figure png example to the disk
fd_plot = function(fdObj, id) {
    file_path = file.path(fdObj$dir, "figures", paste0(id, ".png"))
    canvas_options = fdObj$env[[id]]$canvas_options
    g = fdObj$env[[id]]$g_updated
    lock = lock(file.path(fdObj$dir, "/db.lock"), exclusive = TRUE)
    ggsave(file_path, plot = g, 
           width = canvas_options$width, 
           height = canvas_options$height, 
           units = canvas_options$units, 
           dpi = canvas_options$dpi)
    unlock(lock)
    fd_save(fdObj)
}


#' Initiates the ggfigdone database
#' 
#' This function creates a directory serves as a database for ggfigdone.
#'
#' @param dir A character string of the directory path
#' @param recursive A logical value. If TRUE, the function creates the directory and its parent directories if they do not exist. If FALSE, the function creates the directory only if its parent directory exists.
#' @return An object of class `fdObj`
#' @examples
#' ## create ggfigdone database in a temporary directory
#' db_dir = tempdir()
#' 
#' ## Initate the ggfigdone database
#' fd_init(db_dir)
#'
#' @export
fd_init = function(dir, recursive = TRUE) {
    if (!dir.exists(dir)) {
        dir.create(dir, recursive = recursive)
        dir.create(file.path(dir, "figures"))
    }

    env = new.env()
    readr::write_rds(env, file.path(dir, "env.rds"))

    fd_load(dir)
}

#' Load the ggfigdone database
#' 
#' This function loads the ggfigdone database from the disk.
#' 
#' @param dir A character string of the directory path
#' @return An object of class `fdObj`
#' @examples
#' ## create ggfigdone database in a temporary directory
#' db_dir = tempdir()
#' fd_init(db_dir)
#'
#' ## Load the ggfigdone database
#' fd_load(db_dir)
#'
#' @export
fd_load = function(dir) {
    lock = lock(file.path(dir, "/db.lock"), exclusive = FALSE)
    if (!dir.exists(dir)) {
        stop("Directory does not exist")
    }

    env = readr::read_rds(file.path(dir, "env.rds"))
    unlock(lock)

    obj = list(
        env = env,
        dir = dir
    )

    class(obj) = "fdObj"

    # message("==================\nfdObj is loaded successfully...\nSave the ggfigdone data to the disk using fd_save function.\nIf you forgot, no worries.\nit will be saved automatically when you exit the R session.\n==================")

    # reg.finalizer(.GlobalEnv, function(e) {
        # message("Saving the ggfigdone data to the disk...")
        # fd_save(obj)
        # message("Done Bye Bye ..")
    # },onexit=TRUE)

    obj
}

#' Add a ggplot object to the ggfigdone database
#'
#' This function adds a ggplot object to the ggfigdone database, which also can be used to update the figure given the figure id.
#' 
#' @param g A ggplot object
#' @param name A character string of the figure name
#' @param fdObj An object of class `fdObj`
#' @param width A numeric value of the width of the canvas
#' @param height A numeric value of the height of the canvas
#' @param units A character string of the units of the canvas
#' @param dpi A numeric value of the dpi of the canvas
#' @param overwrite A logical value. If TRUE, the function overwrites the figure if it already exists. If FALSE, the function stops with an error message.
#' @param id A character string of the figure id. If not provided, the function generates a random id. Otherwise, you can give an existing id to update the corresponding figure.
#' @return An object of class `fdObj`
#' @examples
#'
#' ## Initial ggfigdone database using `fd_init`
#' db_dir = tempdir()
#' fo = fd_init(db_dir)
#' 
#' ## Draw a ggplot figure
#' g = ggplot(mtcars, aes(x=wt, y=mpg)) + geom_point()
#' 
#' ## Add the figure to the database
#' fd_add(g = g, name  = "fig1", fo)
#' 
#' ## Add the same figure with a different name
#' fd_add(g = g, name  = "fig2", fo)
#' 
#' ## Show the updated ggfigdone database
#' print(fo)
#'
#' @export
fd_add = function(g, name, fdObj,
    width = 5,
    height = 5,
    units = "cm",
    dpi = 600,
    overwrite = F,
    id = uuid::UUIDgenerate()) 
{
    fd_update(fdObj)
    if (id %in% names(fdObj$env) && !overwrite) {
        stop("Figure already exists")
    }
    figObj = list(
        g_origin = g,
        g_updated = g,
        name = name,
        id = id,
        created_date = Sys.time(),
        updated_date = Sys.time(),
        update_history = c(),
        canvas_options = list(
            width = width,
            height = height,
            units = units,
            dpi = dpi
        )
    )
    class(figObj) = "figObj"
    ## Add figObj to the environment
    fdObj$env[[id]] = figObj
    fd_plot(fdObj, id)
}

#' @export
format.fdObj = function(fdObj) {
    fd_update(fdObj)
    lapply(names(fdObj$env), function(id) {


        data.table::data.table(
            id = id,
            name = fdObj$env[[id]]$name,
            created_date = fdObj$env[[id]]$created_date,
            updated_date = fdObj$env[[id]]$updated_date,
            width = fdObj$env[[id]]$canvas_options$width,
            height = fdObj$env[[id]]$canvas_options$height,
            units = fdObj$env[[id]]$canvas_options$units,
            dpi = fdObj$env[[id]]$canvas_options$dpi,
            file_name = file.path(paste0(id, ".png"))
        )
    }) |> data.table::rbindlist()
}

#' @export
print.fdObj = function(fdObj) {
    format(fdObj)
}

#' List the figures
#' 
#' This function returns figures with their parameters.
#' The parameters include:
#' - id: the figure id
#' - name: the figure name
#' - created_date: the created date
#' - updated_date: the updated date
#' - width: the width of the canvas
#' - height: the height of the canvas
#' - units: the units of the canvas
#' - dpi: the dpi of the canvas
#' - file_name: the file name
#' - plot_labels: the plot labels
#'
#' @param fdObj An object of class `fdObj`
#' @return A list of the figures with their parameters
#' @export
fd_ls = function(fdObj) {
    fd_update(fdObj)
    lapply(names(fdObj$env), function(id) {

        plot_labels = fdObj$env[[id]]$g_updated$labels

        list(
            id = id,
            name = fdObj$env[[id]]$name,
            created_date = fdObj$env[[id]]$created_date,
            updated_date = fdObj$env[[id]]$updated_date,
            width = fdObj$env[[id]]$canvas_options$width,
            height = fdObj$env[[id]]$canvas_options$height,
            units = fdObj$env[[id]]$canvas_options$units,
            dpi = fdObj$env[[id]]$canvas_options$dpi,
            file_name = file.path(paste0(id, ".png")),
            plot_labels = plot_labels
        )
    })
}

#' Remove a figure
#' 
#' This function removes a figure from the ggfigdone database.
#'
#' @param id A character string of the figure id
#' @param fdObj An object of class `fdObj`
#' @export
fd_rm = function(id, fdObj) {
    fd_update(fdObj)
    if (id %in% names(fdObj$env)) {
        lock = lock(file.path(fdObj$dir, "/db.lock"), exclusive = TRUE)
        message(paste0("Figure ", fdObj$env[[id]]$name,  " is removed."))
        file.remove(file.path(fdObj$dir, "figures", paste0(id, ".png")))
        rm(list = id, envir = fdObj$env)
        unlock(lock)
        fd_save(fdObj)
        message("Figure is removed.")
    } else {
        message("Figure does not exist")
    }
}

## TODO: Add function to recover the original figure
fd_back_to_origin = function(id, fdObj) {
    fd_update(fdObj)
    if (id %in% names(fdObj$env)) {
        fdObj$env[[id]]$update_histroy = c()
        fdObj$env[[id]]$updated_date = Sys.time()
        fd_plot(fdObj, id)
    }
}

#' Update a figure using ggplot expression
#'
#' This function updates a figure using a ggplot expression.
#'
#' @param id A character string of the figure id
#' @param expr A character string of the ggplot expression
#' @param fdObj An object of class `fdObj`
#' @return A character string of the status
#' @export
fd_update_fig = function(id, expr, fdObj) {
    fd_update(fdObj)
    if (id %in% names(fdObj$env)) {
        g = fdObj$env[[id]]$g_origin
        update_history = fdObj$env[[id]]$update_history
        update_history = c(update_history, expr)
        expr_new = paste0("g +", paste(update_history, collapse = " + "))
        g = try(eval(parse(text = expr_new)))
        # Update the environment when the figure is updated
        if (inherits(g, "try-error")) {
            return(g)
        } else {
            fdObj$env[[id]]$update_history = update_history
            fdObj$env[[id]]$g_updated = g
            fdObj$env[[id]]$updated_date = Sys.time()
            fd_plot(fdObj, id)

            return("OK")
        }
    } else {
        return("Figure does not exist")
    }
}

## TODO: Browse the editing history of a figure
fd_update_ls = function(id, fdObj) {
    fd_update(fdObj)
    if (id %in% names(fdObj$env)) {
        fdObj$env[[id]]$update_history
    }
}

## TODO: Specifically remove an change of a figure
fd_update_rm = function(id, index, fdObj) {
    fd_update(fdObj)
    if (id %in% names(fdObj$env)) {
        g = fdObj$env[[id]]$g_origin
        update_history = fdObj$env[[id]]$update_history
        update_history = update_history[-index]
        fdObj$env[[id]]$update_history = update_history
        expr_new = paste0("g +", paste(update_history, collapse = " + "))
        g = eval(parse(text = expr_new))
        fdObj$env[[id]]$g_updated = g
        fdObj$env[[id]]$updated_date = Sys.time()
        fd_plot(fdObj, id)
    }
}

#' Update the figure canvas size
#' 
#' This function updates the figure canvas size.
#' 
#' @param id A character string of the figure id
#' @param fdObj An object of class `fdObj`
#' @param width A numeric value of the width of the canvas
#' @param height A numeric value of the height of the canvas
#' @param units A character string of the units of the canvas, e.g., "cm", "in", "mm", "px"
#' @export
fd_canvas = function(
    id, 
    fdObj,
    width = fdObj$env[[id]]$canvas_options$width,
    height = fdObj$env[[id]]$canvas_options$height,
    units = fdObj$env[[id]]$canvas_options$units
) {
    fd_update(fdObj)
    if (id %in% names(fdObj$env)) {
        fdObj$env[[id]]$canvas_options$width = width
        fdObj$env[[id]]$canvas_options$height = height
        fdObj$env[[id]]$canvas_options$units = units
        fdObj$env[[id]]$updated_date = Sys.time()
        fd_plot(fdObj, id)
    }
}


