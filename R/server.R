# font_list = sort(unique(sysfonts::font_files()$family))

response_fd_str_data = function(fo, req) {
    # print("response_fd_str_data")
    parsed_qeury = parse_url(req$QUERY_STRING)$query
    figure_id = parsed_qeury$id
    res = fd_str_data(fo, figure_id)
    if (res$status == "error") {
        list(
            status = 400L,
            headers = list('Content-Type' = "text/plain"),
            body = res$message
        )
    } else {
        list(
            status = 200L,
            headers = list('Content-Type' = "text/plain"),
            body = res$message
        )
    }
}

response_fd_download_data = function(fo, req) {
    # print("response_fd_download_data")
    parsed_qeury = parse_url(req$QUERY_STRING)$query
    figure_id = parsed_qeury$id
    res = fd_generate_data(fo, figure_id)
    if (res$status == "error") {
        list(
            status = 400L,
            headers = list('Content-Type' = "text/plain"),
            body = res$message
        )
    } else {
        list(
            status = 200L,
            headers = list('Content-Type' = "text/plain"),
            body = res$message
        )
    }
}

response_fd_download_pdf = function(fo, req) {
    print("response_fd_download_pdf")
    parsed_qeury = parse_url(req$QUERY_STRING)$query
    figure_id = parsed_qeury$id
    res = fd_generate_pdf(fo, figure_id)
    if (res$status == "error") {
        list(
            status = 400L,
            headers = list('Content-Type' = "text/plain"),
            body = res$message
        )
    } else {
        list(
            status = 200L,
            headers = list('Content-Type' = "text/plain"),
            body = res$message
        )
    }
}

response_fd_change_name = function(fo, req) {
    # print("response_fd_change_name")
    parsed_qeury = parse_url(req$QUERY_STRING)$query
    figure_id = parsed_qeury$id
    new_name = parsed_qeury$new_name
    fd_change_name(figure_id, new_name, fo)
    list(
        status = 200L,
        headers = list('Content-Type' = "text/plain"),
        body = "OK"
    )
}

response_fd_font_ls = function() {
    list(
        status = 200L,
        headers = list('Content-Type' = "application/json"),
        body = toJSON(font_list, auto_unbox = F)
    )
}


response_fd_ls = function(fo) {
    # print("response_fd_ls")
    list(
        status = 200L,
        headers = list('Content-Type' = "application/json"),
        body = toJSON(fd_ls(fo), auto_unbox = F)
    )
}

response_fd_canvas = function(fo, req) {
    # print("response_fd_canvas")
    parsed_qeury = parse_url(req$QUERY_STRING)$query
    figure_name = parsed_qeury$id
    width = as.numeric(parsed_qeury$width)
    height = as.numeric(parsed_qeury$height)
    units = parsed_qeury$units
    dpi = as.numeric(parsed_qeury$dpi)
    # print(figure_name)
    fd_canvas(figure_name, fo, width, height, units, dpi)
    list(
        status = 200L,
        headers = list('Content-Type' = "text/plain"),
        body = "OK"
    )
}

response_fd_update_fig = function(fo, req) {
    # print("response_fd_update_fig")
    input <- req[["rook.input"]]
    ## get the data from the POST request
    postdata <- input$read_lines()
    parsed_qeury = jsonlite::fromJSON(postdata)
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

response_fd_rm = function(fo, req) {
    # print("response_fd_rm")
    parsed_qeury = parse_url(req$QUERY_STRING)$query
    figure_id = parsed_qeury$id
    fd_rm(figure_id, fo)
    list(
        status = 200L,
        headers = list('Content-Type' = "text/plain"),
        body = "OK"
    )
}

#' Start a server for ggfigdone
#' 
#' @param dir The directory to save the figures
#' @param port The port of the server, default is 8080
#' @export
fd_server = function(dir, port = 8080) {
    fo = fd_load(dir)

    # print(fd_ls(fo))
    # print(format(fo))

    # on.exit(fd_save(fo))

    www_dir = system.file("www", package = "ggfigdone")

    # create a server
    # which can change the file size, and the figure will be updated
    app = list(
        call = function(req) {
            # print(fd_ls(fo))
            # print(format(fo))
            ## req:
            # PATH_INFO: the path of the request
            # QUERY_STRING: the query string of the request

            path = req$PATH_INFO
            # print(path)
            if (path == "/fd_ls") {
                response_fd_ls(fo)
            } else if (path == "/fd_rm") {
                response_fd_rm(fo, req)
            } else if (path == "/fd_update_fig") {
                response_fd_update_fig(fo, req)
            } else if (path == "/fd_update_ls") {
            } else if (path == "/fd_update_rm") {
            } else if (path == "/fd_font_ls") {
                response_fd_font_ls()
            } else if (path == "/fd_canvas") {
                response_fd_canvas(fo, req) 
            } else if (path == "/fd_change_name") {
                response_fd_change_name(fo, req)
            } else if (path == "/fd_download_pdf") {
                response_fd_download_pdf(fo, req)
            } else if (path == "/fd_download_data") {
                response_fd_download_data(fo, req)
            } else if (path == "/fd_str_data") {
                response_fd_str_data(fo, req)
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
            "/tmp" = file.path(dir, "tmp"),
            "/css" = file.path(www_dir, "css"),
            "/js" = file.path(www_dir, "js"),
            "/index.html" = file.path(www_dir, "index.html")
        )
    )

    # start the server
    message_text = paste0("Start service: http://localhost:", port, "/index.html")
    message(message_text)
    runServer(host = "0.0.0.0", port = port, app = app)
}


