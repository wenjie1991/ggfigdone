library(ggplot2)
library(httpuv)
library(httr)
library(jsonlite)

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


fd_load = function(dir) {
    if (!dir.exists(dir)) {
        stop("Directory does not exist")
    }

    env = readr::read_rds(file.path(dir, "env.rds"))

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

fd_plot = function(fdObj, id) {
    file_path = file.path(fdObj$dir, "figures", paste0(id, ".png"))
    canvas_options = fdObj$env[[id]]$canvas_options
    g = fdObj$env[[id]]$g_updated
    ggsave(file_path, plot = g, 
           width = canvas_options$width, 
           height = canvas_options$height, 
           units = canvas_options$units, 
           dpi = canvas_options$dpi)
}

fd_add = function(g, name, fdObj,
    width = 5,
    height = 5,
    units = "cm",
    dpi = 600,
    overwrite = F,
    id = uuid::UUIDgenerate()) 
{
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

format.fdObj = function(fdObj) {
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
            file_name = file.path(paste0(id, ".png")),
        )
    }) |> data.table::rbindlist()
}

fd_ls = function(fdObj) {
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

fd_rm = function(id, fdObj) {
    if (id %in% names(fdObj$env)) {
        message(paste0("Figure ", fdObj$env[[id]]$name,  " is removed."))
        file.remove(file.path(fdObj$dir, "figures", paste0(id, ".png")))
        rm(list = id, envir = fdObj$env)
    }
}

fd_update_fig = function(id, expr, fdObj) {
    ## TODO: keep the history of the changes
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

fd_update_ls = function(id, fdObj) {
    if (id %in% names(fdObj$env)) {
        fdObj$env[[id]]$update_history
    }
}

fd_update_rm = function(id, index, fdObj) {
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

fd_canvas = function(
    id, 
    fdObj,
    width = fdObj$env[[id]]$canvas_options$width,
    height = fdObj$env[[id]]$canvas_options$height,
    units = fdObj$env[[id]]$canvas_options$units
) {
    if (id %in% names(fdObj$env)) {
        fdObj$env[[id]]$canvas_options$width = width
        fdObj$env[[id]]$canvas_options$height = height
        fdObj$env[[id]]$canvas_options$units = units
        fdObj$env[[id]]$updated_date = Sys.time()
        fd_plot(fdObj, id)
    }
}

fd_save = function(fdObj) {
    message("Saving the ggfigdone data to the disk...")
    readr::write_rds(fdObj$env, file.path(fdObj$dir, "env.rds"))
}

############
#  Server  #
############

library(sysfonts)
font_list = sort(unique(sysfonts::font_files()$family))

response_fg_font_ls = function() {
    list(
        status = 200L,
        headers = list('Content-Type' = "application/json"),
        body = toJSON(font_list, auto_unbox = F)
    )
}


response_fg_ls = function(fo) {
    # print("response_fg_ls")
    list(
        status = 200L,
        headers = list('Content-Type' = "application/json"),
        body = toJSON(fd_ls(fo), auto_unbox = F)
    )
}

response_fg_canvas = function(fo, req) {
    # print("response_fg_canvas")
    parsed_qeury = parse_url(req$QUERY_STRING)$query
    figure_name = parsed_qeury$id
    width = as.numeric(parsed_qeury$width)
    height = as.numeric(parsed_qeury$height)
    units = parsed_qeury$units
    fd_canvas(figure_name, fo, width, height, units)
    list(
        status = 200L,
        headers = list('Content-Type' = "text/plain"),
        body = "OK"
    )
}

response_fg_update_fig = function(fo, req) {
    # print("response_fg_update_fig")
    parsed_qeury = parse_url(req$QUERY_STRING)$query
    figure_name = parsed_qeury$id
    expr = parsed_qeury$gg_code
    res = fd_update_fig(figure_name, expr, fo)
    if (inherits(res, "try-error")) {
        list(
            status = 400L,
            headers = list('Content-Type' = "text/plain"),
            body = "Error: The ggplot code is not valide"
        )
    } else {
        list(
            status = 200L,
            headers = list('Content-Type' = "text/plain"),
            body = "OK"
        )
    }
}

response_fg_rm = function(fo, req) {
    # print("response_fg_rm")
    parsed_qeury = parse_url(req$QUERY_STRING)$query
    figure_id = parsed_qeury$id
    fd_rm(figure_id, fo)
    list(
        status = 200L,
        headers = list('Content-Type' = "text/plain"),
        body = "OK"
    )
}

fd_server = function(dir) {
    fo = fd_load(dir)

    on.exit(fd_save(fo))

    www_dir = system.file("www", package = "ggfigdone")

    # create a server
    # which can change the file size, and the figure will be updated
    app = list(
        call = function(req) {
            ## req:
            # PATH_INFO: the path of the request
            # QUERY_STRING: the query string of the request

            path = req$PATH_INFO
            # print(path)
            if (path == "/fd_ls") {
                response_fg_ls(fo)
            } else if (path == "/fd_rm") {
                response_fg_rm(fo, req)
            } else if (path == "/fd_update_fig") {
                response_fg_update_fig(fo, req)
            } else if (path == "/fd_update_ls") {
            } else if (path == "/fd_update_rm") {
            } else if (path == "/fd_font_ls") {
                response_fg_font_ls()
            } else if (path == "/fd_canvas") {
                response_fg_canvas(fo, req)
            } else {
                list(
                    status = 404L,
                    headers = list('Content-Type' = "text/plain"),
                    body = "Not Found"
                )
            }
        },
        staticPaths = list(
            "/figure" = file.path(dir, "figures"),
            "/css" = file.path(www_dir, "css"),
            "/js" = file.path(www_dir, "js"),
            "/index.html" = file.path(www_dir, "index.html")
        )
    )

    # start the server
    message("Start service: http://localhost:8080/index.html")
    runServer(host = "0.0.0.0", port = 8080, app = app)
}


