.db_store <- function() {
    .last_db = NULL

    list(
        get = function() .last_db,
        set = function(x) .last_db <<- x
    )
}
.db <- .db_store()

#' Set the default ggfigdone database
#' 
#' @param fdObj An object of class `fdObj` to be set as the default ggfigdone database.
#' @return No return value, the default ggfigdone database is set to an environment variable.
#' @export
fd_set_db = function(fdObj) {
    .db$set(fdObj)
}

#' Get the default ggfigdone database
#'
#' @return An object of class `fdObj` representing the default ggfigdone database.
#' @export
fd_get_db = function() {
    .db$get()
}

#' Merge ggfigdone databases
#'
#' This function merges two ggfigdone databases. 
#' The function will update the figures in the 'to' database with the figures in the 'from' database.
#' If there is a figure with the same ID in both databases, the function will keep the figure with the latest updated date or created date.
#' 
#' @param from An object of class `fdObj` that will be merged from.
#' @param to An object of class `fdObj` that will be merged to. The default value is the default ggfigdone database.
#' @param replace A character string specifying the method to keep the figure with the unique ID. It can be either "updated_date" or "created_date".
#' @return An object of class `fdObj` with the merged database.
#' @export
#' @examples
#' library(ggplot2)
#' ## create ggfigdone database in a temporary directory
#' db_dir1 = file.path(tempdir(), "db1")
#' db_dir2 = file.path(tempdir(), "db2")
#' fo1 = fd_init(db_dir1, rm_exist = TRUE)
#' fo2 = fd_init(db_dir2, rm_exist = TRUE)
#'
#' ## Draw a ggplot figure
#' g = ggplot(mtcars, aes(x=wt, y=mpg)) + geom_point()
#'
#' ## Add the figure to the database
#' fd_add(g = g, name  = "fig1", fdObj = fo1)
#' fd_add(g = g + theme_classic(), name  = "fig2", fdObj = fo2)
#' 
#' ## Merge the databases
#' fo_merge = fd_merge(from = fo1, to = fo2, replace = "updated_date")
#'
#' ## Show the updated ggfigdone database
#' print(fo_merge)
#'
#' ##
fd_merge = function(from, to = fd_get_db(), replace = "updated_date") {

    if (!inherits(from, "fdObj") || !inherits(to, "fdObj")) {
        stop("The 'from' and 'to' arguments should be objects of class 'fdObj'")
    }
    if (replace != "updated_date" && replace != "created_date") {
        stop("The 'replace' argument should be either 'updated_date' or 'created_date'")
    }

    # fd_update(from)
    # fd_update(to)
    lock_to = lock(file.path(to$dir, "/db.lock"), exclusive = TRUE)
    lock_from = lock(file.path(from$dir, "/db.lock"), exclusive = FALSE)

    ## Merge the databases
    for (id in names(from$env)) {
        if (id %in% names(to$env)) {
            if (replace == "updated_date") {
                if (from$env[[id]]$updated_date > to$env[[id]]$updated_date) {
                    to$env[[id]] = from$env[[id]]
                    fd_plot(to, id, do_lock = FALSE)
                }
            } else {
                if (from$env[[id]]$created_date > to$env[[id]]$created_date) {
                    to$env[[id]] = from$env[[id]]
                    fd_plot(to, id, do_lock = FALSE)
                }
            }
        } else {
            to$env[[id]] = from$env[[id]]
            fd_plot(to, id, do_lock = FALSE)
        }
    }
    unlock(lock_to)
    unlock(lock_from)
    to
}



#' Keep figure name unique by removing older figures with the same name
#'
#' This function keeps the figure name unique by removing the older figures with the same name.
#' Users can specify whether to keep the figure with the latest updated date or the latest created date.
#' If a figure is created without changing, the created date and updated date are the same.
#' 
#' @param fdObj An object of class `fdObj`.
#' @param by A character string specifying the method to keep the figure with the unique name. It can be either "updated_date" or "created_date".
#' @return An object of class `fdObj`.
#' @export
#' @examples
#' library(ggplot2)
#' ## create ggfigdone database in a temporary directory
#' db_dir = file.path(tempdir(), "fd_unique")
#' fo = fd_init(db_dir, rm_exist = TRUE)
#'
#' ## Draw a ggplot figure
#' g = ggplot(mtcars, aes(x=wt, y=mpg)) + geom_point()
#'
#' ## Add the figure to the database
#' fd_add(g = g, name  = "fig1", fdObj = fo)
#'
#' ## Add the another figure with the same name
#' fd_add(g = g + theme_classic(), name  = "fig1", fdObj = fo)
#' 
#' ## Keep the figure with the latest created date
#' fd_unique(fdObj = fo, by = "created_date")
#'
#' ## Show the updated ggfigdone database
#' print(fo)
#'
fd_unique = function(fdObj = fd_get_db(), by = "updated_date") {
    fd_update(fdObj)
    lock = lock(file.path(fdObj$dir, "/db.lock"), exclusive = TRUE)
    unique_names = unique(sapply(fdObj$env, function(x) x$name))

    for (name in unique_names) {
        ids = names(fdObj$env)[sapply(fdObj$env, function(x) x$name == name)]

        if (length(ids) == 1) {
            next
        }

        ## Get old figure id
        if (by == "updated_date") {
            new_id = ids[which.max(sapply(ids, function(x) fdObj$env[[x]]$updated_date))]
            v_old_id = ids[ids != new_id]
        } else if (by == "created_date") {
            new_id = ids[which.max(sapply(ids, function(x) fdObj$env[[x]]$created_date))]
            v_old_id = ids[ids != new_id]
        } else {
            unlock(lock)
            stop("The 'by' argument should be either 'updated_date' or 'created_date'")
        }

        ## Remove the older figures
        rm(list = v_old_id, envir = fdObj$env)
        for (id in v_old_id) {
            file.remove(file.path(fdObj$dir, "figures", paste0(id, ".png")))
        }
        message(paste0(length(v_old_id), " figures with the name '", name, "' are removed."))
    }
    fd_save(fdObj, do_lock = FALSE)
    unlock(lock)
    fdObj
}

## Update the figure name
fd_change_name = function(id, name, fdObj) {
    fd_update(fdObj)
    lock = lock(file.path(fdObj$dir, "/db.lock"), exclusive = TRUE)
    if (id %in% names(fdObj$env)) {
        fdObj$env[[id]]$name = name
        fdObj$env[[id]]$updated_date = Sys.time()
    }
    fd_save(fdObj, do_lock = FALSE)
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
        if (do_lock) {
            unlock(lock)
        }
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

#' Update the ggfigdone database changes **to the disk**
#'
#' This function saves the ggfigdone data to the disk.
#' By default, when using the \code{\link[ggfigdone]{fd_load}} funciton to load the databse, the data will be automatically saved to the disk when changes are made.
#' But if you set the \code{auto_database_upgrade} argument to \code{FALSE} in \code{\link[ggfigdone]{fd_load}}, you need to manually save the data using this function.
#' 
#' @param fdObj An object of class `fdObj`.
#' @param do_lock A logical value. If TRUE, the function will lock the database file when saving the data.
#' @return No return value, changes are made directly to the ggfigdone database.
#' @export
fd_save = function(fdObj = fd_get_db(), do_lock = TRUE) {
    message("Automatic saving the ggfigdone data to the disk ...")
    if (do_lock) {
        lock = lock(file.path(fdObj$dir, "/db.lock"), exclusive = TRUE)
    }
    readr::write_rds(fdObj$env, file.path(fdObj$dir, "env.rds"))
    if (do_lock) {
        unlock(lock)
    }
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
        readr::write_csv(data, csv_file)
        status = "ok"
        message(paste0("The csv file is saved to ", csv_file))
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
        message(paste0("The pdf file is saved to ", pdf_file))
    }
    return(list(
        status = status,
        message = status
    ))
}

## Generate png for displaying in the UI
fd_plot = function(fdObj, id, do_lock = TRUE) {
    file_path = file.path(fdObj$dir, "figures", paste0(id, ".png"))
    canvas_options = fdObj$env[[id]]$canvas_options
    g = fdObj$env[[id]]$g_updated
    if (do_lock) {
        lock = lock(file.path(fdObj$dir, "/db.lock"), exclusive = TRUE)
    }
    ggsave(file_path, plot = g, 
           width = canvas_options$width, 
           height = canvas_options$height, 
           units = canvas_options$units, 
           dpi = canvas_options$dpi)
    if (do_lock) {
        unlock(lock)
    }
}


#' Initiates the ggfigdone database
#' 
#' This function generates a folder that serves as a database for ggfigdone.
#'
#' @param dir A character string specifying the directory path.
#' @param recursive A logical value. If TRUE, the function will create the directory along with any necessary parent directories if they do not already exist. If FALSE, the function will create the directory only if its parent directory already exists.
#' @param rm_exist A logical value. If TRUE, the function will remove the content in the directory if it already exists. If FALSE, the function will ask the user whether to remove the content in the directory.
#' @param ... Additional arguments to be passed to \code{\link[ggfigdone]{fd_load}} function.
#' @param set_default A logical value. If TRUE, the function will set the database as the default database.
#' @return An object of class `fdObj`.
#' @examples
#' library(ggplot2)
#' ## create ggfigdone database in a temporary directory
#' db_dir = file.path(tempdir(), "fd_init")
#' 
#' ## Initate the ggfigdone database
#' fd_init(db_dir, rm_exist = TRUE)
#'
#' @export
fd_init = function(dir, recursive = TRUE, rm_exist = FALSE, set_default = TRUE, ...) {
    ## check if the dir is empty
    if (!dir.exists(dir)) {
        dir.create(dir, recursive = recursive)
    } else if (length(dir(dir)) == 0) {
    } else {
        message("The directory already exists, and is not empty.")
        if (!rm_exist) {
            rm_exist = readline("Do you want to remove the content in the directory? (y/n): ") == 'y'
        }
        if (rm_exist) {
            message("The directory content is removed.")
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

    fd_load(dir, set_default = set_default, ...)
}

#' Load the ggfigdone database
#' 
#' This function loads the ggfigdone database from the disk.
#' 
#' @param dir A character string representing the directory path.
#' @param auto_database_upgrade A logical value. If TRUE, the function will automatically upgrade the database to the latest version. 
#' If FALSE, you need to manually save the data using the \code{\link[ggfigdone]{fd_save}} function.
#' @param set_default A logical value. If TRUE, the function will set the database as the default database.
#' @return An object of class `fdObj`.
#' @examples
#' library(ggplot2)
#' ## create ggfigdone database in a temporary directory
#' db_dir = file.path(tempdir(), "fd_load")
#' fd_init(db_dir, rm_exist = TRUE)
#'
#' ## Load the ggfigdone database
#' fd_load(db_dir)
#'
#' @export
fd_load = function(dir, auto_database_upgrade = TRUE, set_default = TRUE) {
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

    if (set_default) {
        fd_set_db(obj)
    }

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
#' db_dir = file.path(tempdir(), "fd_add_exp")
#' fo = fd_init(db_dir, rm_exist = TRUE)
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
fd_add = function(name, g = last_plot(), fdObj = fd_get_db(),
    width = 10,
    height = 10,
    units = "cm",
    dpi = 200,
    overwrite = FALSE,
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
    fd_save(fdObj)
}

#' @export
format.fdObj = function(x, ...) {
    fd_update(x)
    cat("##########")
    cat("\n")
    cat(paste0("## ggfigdone database: ", x$dir))
    cat("\n")
    cat(paste0("## Number of figures: ", length(x$env)))
    cat("\n")
    ## Last updated date
    if (length(x$env) == 0) {
        cat(paste0("## Last updated date: "))
        cat(as.character(Sys.time()))
        cat("\n")
    } else {
        cat("## Last updated date: ")
        cat(format(as.POSIXct(max(sapply(x$env, function(x) x$updated_date))), "%Y-%m-%d %H:%M:%S"))

        cat("\n")
    }
    invisible(x)
}

#' @export
print.fdObj = function(x, ...) {
    format(x, ...)
}

#' List the figures
#' 
#' This function provides a List or data.frame of figures along with their associated parameters.
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
#' @return A List/data.frame containing the figures along with their respective parameters.
#' @export
fd_ls = function(fdObj = fd_get_db()) {
    fd_update(fdObj)
    lapply(names(fdObj$env), function(id) {

        plot_labels = fdObj$env[[id]]$g_updated$labels

        list(
            id = id,
            name = fdObj$env[[id]]$name,
            created_date = fdObj$env[[id]]$created_date,
            updated_date = fdObj$env[[id]]$updated_date,
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

#' @rdname fd_ls
#' @export
fd_df = function(fdObj = fd_get_db()) {
    fd_update(fdObj)
    data.table::rbindlist(lapply(names(fdObj$env), function(id) {
        plot_labels = fdObj$env[[id]]$g_updated$labels
        data.table::data.table(
            id = id,
            name = fdObj$env[[id]]$name,
            created_date = fdObj$env[[id]]$created_date,
            updated_date = fdObj$env[[id]]$updated_date,
            code_updated = fdObj$env[[id]]$code_updated,
            width = fdObj$env[[id]]$canvas_options$width,
            height = fdObj$env[[id]]$canvas_options$height,
            units = fdObj$env[[id]]$canvas_options$units,
            dpi = fdObj$env[[id]]$canvas_options$dpi,
            file_name = file.path(paste0(id, ".png")),
            plot_labels = plot_labels
        )
    })) |> as.data.frame()
}


#' Remove a figure
#' 
#' This function removes a figure from the ggfigdone database.
#'
#' @param id A character string representing the figure ID.
#' @param fdObj An object of class `fdObj`.
#' @return No return value, changes are made directly to the ggfigdone database.
#' @export
fd_rm = function(id, fdObj = fd_get_db()) {
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
fd_update_fig = function(id, expr, fdObj = fd_get_db()) {
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
    fd_save(fdObj, do_lock = FALSE)
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
#' @return No return value, changes are made directly to the ggfigdone database.
#' @export
fd_canvas = function(
    id, 
    fdObj = fd_get_db(),
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
        lock = lock(file.path(fdObj$dir, "/db.lock"), exclusive = TRUE)
        fd_plot(fdObj, id, do_lock = FALSE)
        fd_save(fdObj, do_lock = FALSE)
        unlock(lock)
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

