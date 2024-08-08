## Update the figure name
fd_change_name = function(id, name, fdObj) {
    fd_update(fdObj)
    lock = lock(file.path(fdObj$dir, "/db.lock"), exclusive = TRUE)
    if (id %in% names(fdObj$env)) {
        fdObj$env[[id]]$name = name
        fdObj$env[[id]]$updated_date = Sys.time()
    }
    unlock(lock)
}


## Update fdObj by reading the data **from the disk**
fd_update = function(fdObj_loc, do_lock = TRUE) {

    ## Get the fdObj name in the parent environment of the parent environment
    fdObj_global = as.character(substitute(fdObj, env = parent.frame(n = 1)))
    ## Get the fdObj name in the parent environment
    fdObj_parent = as.character(substitute(fdObj))

    if (do_lock) {
        lock = lock(file.path(fdObj_loc$dir, "/db.lock"), exclusive = FALSE)
    }
    if (!dir.exists(fdObj_loc$dir)) {
        stop("Directory does not exist")
    }

    ## Load the env
    env = readr::read_rds(file.path(fdObj_loc$dir, "env.rds"))
    fdObj_loc$env = env
    if (do_lock) {
        unlock(lock)
    }

    ## Update the fdObj in the environments
    assign(fdObj_global, fdObj_loc, envir = parent.frame(n = 2))
    assign(fdObj_parent, fdObj_loc, envir = parent.frame(n = 1))
}

## Update the ggfigdone database changes **to the disk**
fd_save = function(fdObj) {
    message("Automatic saving the ggfigdone data to the disk ...")
    lock = lock(file.path(fdObj$dir, "/db.lock"), exclusive = TRUE)
    readr::write_rds(fdObj$env, file.path(fdObj$dir, "env.rds"))
    unlock(lock)
}

## Get the data structure of the data used in ggplot object
fd_str_data = function(fdObj, id) {
    fd_update(fdObj)
    status = "error"
    message = "Figure does not exist"
    if (id %in% names(fdObj$env)) {
        data = fdObj$env[[id]]$data
        status = "ok"
        message = capture.output(str(data)) |> paste(collapse = "\n")
    }
    return(list(
        status = status,
        message = message
    ))
}

## Save the data to a temporary csv file for downloading in the UI
fd_generate_data = function(fdObj, id) {
    fd_update(fdObj)
    status = "error"
    if (id %in% names(fdObj$env)) {
        g = fdObj$env[[id]]$g_updated
        fig_name = fdObj$env[[id]]$name
        csv_file = file.path(fdObj$dir, "tmp", paste0(fig_name, ".csv"))
        data = fdObj$env[[id]]$data
        write.csv(data, csv_file, row.names = FALSE)
        status = "ok"
        print(paste0("The csv file is saved to ", csv_file))
    }
    return(list(
        status = status,
        message = status
    ))
}

## Generate pdf for downloading in the UI
fd_generate_pdf = function(fdObj, id) {
    fd_update(fdObj)
    status = "error"
    if (id %in% names(fdObj$env)) {
        g = fdObj$env[[id]]$g_updated
        fig_name = fdObj$env[[id]]$name
        pdf_file = file.path(fdObj$dir, "tmp", paste0(fig_name, ".pdf"))
        canvas_options = fdObj$env[[id]]$canvas_options
        ggsave(pdf_file, plot = g, 
               width = canvas_options$width, 
               height = canvas_options$height, 
               units = canvas_options$units, 
               dpi = canvas_options$dpi)
        status = "ok"
        print(paste0("The pdf file is saved to ", pdf_file))
    }
    return(list(
        status = status,
        message = status
    ))
}

## Generate png for displaying in the UI
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
#' This function generates a folder that serves as a database for ggfigdone.
#'
#' @param dir A character string specifying the directory path.
#' @param recursive A logical value. If TRUE, the function will create the directory along with any necessary parent directories if they do not already exist. If FALSE, the function will create the directory only if its parent directory already exists.
#' @return An object of class `fdObj`.
#' @examples
#' library(ggplot2)
#' ## create ggfigdone database in a temporary directory
#' db_dir = tempdir()
#' 
#' ## Initate the ggfigdone database
#' fd_init(db_dir)
#'
#' @export
fd_init = function(dir, recursive = TRUE, ...) {
    ## check if the dir is empty
    if (!dir.exists(dir)) {
        dir.create(dir, recursive = recursive)
    } else if (length(dir(dir)) == 0) {
    } else {
        message("The directory already exists, and is not empty.")
        prompt = readline("Do you want to remove the content in the directory? (y/n): ")
        if (prompt == "y") {
            unlink(dir, recursive = TRUE)
            dir.create(dir, recursive = recursive)
        } else {
            message("The directory is not removed. The initialization is stopped.")
            return()
        }
    }

    if (!dir.exists(file.path(dir, "figures"))) {
        dir.create(file.path(dir, "figures"))
    } else {
        unlink(file.path(dir, "figures"), recursive = TRUE)
        dir.create(file.path(dir, "figures"))
    }

    if (!dir.exists(file.path(dir, "tmp"))) {
        dir.create(file.path(dir, "tmp"))
    } else {
        unlink(file.path(dir, "tmp"), recursive = TRUE)
        dir.create(file.path(dir, "tmp"))
    }

    env = new.env()
    readr::write_rds(env, file.path(dir, "env.rds"))

    writeLines("v1", file.path(dir, "version.txt"))

    fd_load(dir, ...)
}

#' Load the ggfigdone database
#' 
#' This function loads the ggfigdone database from the disk.
#' 
#' @param dir A character string representing the directory path.
#' @return An object of class `fdObj`.
#' @examples
#' library(ggplot2)
#' ## create ggfigdone database in a temporary directory
#' db_dir = tempdir()
#' fd_init(db_dir)
#'
#' ## Load the ggfigdone database
#' fd_load(db_dir)
#'
#' @export
fd_load = function(dir, auto_database_upgrade = TRUE) {
    ## Check if the directory exists
    if (!dir.exists(dir)) {
        stop("Directory does not exist")
    }

    ## Empty the tmp directory when the R session is ended
    reg.finalizer(.GlobalEnv, function(e) {
        message("Removing the temporary files...")
        unlink(file.path(dir, "tmp/*"), recursive = TRUE)
        message("Done")
    }, onexit = TRUE)

    ## Check the version of the database
    if (auto_database_upgrade) {
        if (!file.exists(file.path(dir, "version.txt"))) {
            x_version = "v0"
        } else {
            x_version = readLines(file.path(dir, "version.txt"))
        }

        if (x_version == "v0") {
            message(paste0("The database is version 0. It will be transformed to version 1. Please stop other processes that are using the database."))
            transform_db_v02v1(dir)
        } else if (x_version != "v1") { 
            stop(paste0("The version of the database is ", x_version, " which is not supported."))
        } else {
            message("The database version is up-to-date.")
        }
    }

    ## Load the ggfigdone database
    lock = lock(file.path(dir, "/db.lock"), exclusive = FALSE)
    env = readr::read_rds(file.path(dir, "env.rds"))
    unlock(lock)
    obj = list(
        env = env,
        dir = dir
    )

    class(obj) = "fdObj"


    obj
}

#' Add a ggplot object to the ggfigdone database
#'
#' This function adds a ggplot object to the ggfigdone database. It can also be utilized to update an existing figure using its figure ID.
#' 
#' @param g A ggplot object.
#' @param name A character string representing the figure name.
#' @param fdObj An object of class `fdObj`.
#' @param width A numeric value specifying the width of the canvas.
#' @param height A numeric value specifying the height of the canvas.
#' @param units A character string indicating the units of the canvas.
#' @param dpi A numeric value denoting the dpi of the canvas.
#' @param overwrite A logical value. If set to TRUE, the function will overwrite the figure if it already exists. If set to FALSE, the function will terminate with an error message.
#' @param id A character string representing the figure ID. If not provided, the function will generate a random ID. Alternatively, an existing ID can be provided to update the corresponding figure.
#' @return An object of class `fdObj`.
#' @examples
#' library(ggplot2)
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
    dpi = 200,
    overwrite = F,
    id = uuid::UUIDgenerate()) 
{
    fd_update(fdObj)
    if (id %in% names(fdObj$env) && !overwrite) {
        stop("Figure already exists")
    }

    # code_origin = fd_extract_ggplot_code(g)
    code_origin = "g"

    figObj = list(
        g_origin = g,
        g_updated = g,
        data = g$data,
        code_origin = code_origin,
        code_updated = code_origin,
        name = name,
        id = id,
        created_date = Sys.time(),
        updated_date = Sys.time(),
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
#' This function provides a list of figures along with their associated parameters.
#'
#' The parameters include:
#' - id: The unique identifier for the figure
#' - name: The name of the figure
#' - created_date: The date the figure was created
#' - updated_date: The date the figure was last updated
#' - width: The width of the canvas
#' - height: The height of the canvas
#' - units: The units of measurement for the canvas
#' - dpi: The dots per inch (DPI) of the canvas
#' - file_name: The name of the file
#' - plot_labels: The labels used in the plot
#'
#' @param fdObj An instance of the `fdObj` class.
#' @return A list containing the figures along with their respective parameters.
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
            code_origin = fdObj$env[[id]]$code_origin,
            code_updated = fdObj$env[[id]]$code_updated,
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
#' @param id A character string representing the figure ID.
#' @param fdObj An object of class `fdObj`.
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
    return_val = NULL
    lock = lock(file.path(fdObj$dir, "/db.lock"), exclusive = TRUE)
    fd_update(fdObj, do_lock = FALSE)
    if (id %in% names(fdObj$env)) {
        data = fdObj$env[[id]]$data
        g = fdObj$env[[id]]$g_origin
        code_updated = expr
        g = try(eval(parse(text = code_updated)))
        # Update the environment when the figure is updated
        if (inherits(g, "try-error")) {
            return_val = g
        } else {
            fdObj$env[[id]]$code_updated = code_updated
            fdObj$env[[id]]$g_updated = g
            fdObj$env[[id]]$updated_date = Sys.time()
            fd_plot(fdObj, id)

            return_val = "OK"
        }
    } else {
        return_val = "Figure does not exist"
    }
    unlock(lock)
    return(return_val)
}

#' Update the figure canvas size
#' 
#' This function is designed to update the size of the figure canvas.
#' 
#' @param id A character string representing the figure ID.
#' @param fdObj An object of class `fdObj`.
#' @param width A numeric value specifying the width of the canvas.
#' @param height A numeric value specifying the height of the canvas.
#' @param units A character string indicating the units of measurement for the canvas, such as "cm", "in", "mm", or "px".
#' @param dpi A numeric value denoting the dots per inch (DPI) of the canvas.
#' @export
fd_canvas = function(
    id, 
    fdObj,
    width = fdObj$env[[id]]$canvas_options$width,
    height = fdObj$env[[id]]$canvas_options$height,
    units = fdObj$env[[id]]$canvas_options$units,
    dpi = fdObj$env[[id]]$canvas_options$dpi
) {
    fd_update(fdObj)
    if (id %in% names(fdObj$env)) {
        fdObj$env[[id]]$canvas_options$width = width
        fdObj$env[[id]]$canvas_options$height = height
        fdObj$env[[id]]$canvas_options$units = units
        fdObj$env[[id]]$canvas_options$dpi = dpi
        fdObj$env[[id]]$updated_date = Sys.time()
        fd_plot(fdObj, id)
    }
}

## extract code from the ggplot object
## Deprecated: This function is not used anymore, wait the {constuctive} package to be improved
# fd_extract_ggplot_code = function(g) {
#     ## Extract the original code from ggplot object
#     code = constructive:::.cstr_construct(g$mapping)
#     code = constructive:::pipe_to_layers(code, g$layers, plot_env = g$plot_env, one_liner = TRUE)
#     code = constructive:::pipe_to_facets(code, g$facet, one_liner = TRUE)
#     code = constructive:::pipe_to_labels(code, g$labels, g$mapping, g$layers, one_liner = TRUE)
#     code = constructive:::pipe_to_scales(code, g$scales, one_liner = TRUE)
#     code = constructive:::pipe_to_theme(code, g$theme, one_liner = TRUE)
#     code = constructive:::pipe_to_coord(code, g$coordinates, one_liner = TRUE)
#     code = constructive:::repair_attributes_ggplot(g, code, one_liner = TRUE)
#     code = paste0("ggplot(data) + ", gsub("ggplot2::", "", code))
#     code
# }

## TODO: Add function to recover the original figure
# fd_back_to_origin = function(id, fdObj) {
#     fd_update(fdObj)
#     if (id %in% names(fdObj$env)) {
#         fdObj$env[[id]]$update_histroy = c()
#         fdObj$env[[id]]$updated_date = Sys.time()
#         fd_plot(fdObj, id)
#     }
# }



