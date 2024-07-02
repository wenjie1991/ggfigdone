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



#' @export
fd_init = function(dir) {
    if (!dir.exists(dir)) {
        dir.create(dir)
        dir.create(file.path(dir, "figures"))
    }

    ## TODO: Configure the Rprofile

    # write("", "Fdprofile.R", append = F)

    env = new.env()
    readr::write_rds(env, file.path(dir, "env.rds"))

    fd_load(dir)
}


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
        ),
        theme_options = list(
            font_family = ""
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
            plot_labels = plot_labels,
            theme_options = fdObj$env[[id]]$theme_options
        )
    })
}

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
    } else {
        message("Figure does not exist")
    }
}

#' @export
fd_update_fig = function(id, expr, fdObj) {
    ## TODO: keep the history of the changes
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

#' @export
fd_update_ls = function(id, fdObj) {
    fd_update(fdObj)
    if (id %in% names(fdObj$env)) {
        fdObj$env[[id]]$update_history
    }
}

#' @export
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

#' @export
fd_save = function(fdObj) {
    message("Saving the ggfigdone data to the disk...")
    lock = lock(file.path(fdObj$dir, "/db.lock"), exclusive = TRUE)
    readr::write_rds(fdObj$env, file.path(fdObj$dir, "env.rds"))
    unlock(lock)
}


