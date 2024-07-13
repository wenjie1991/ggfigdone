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
    # print(figure_name)
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
    message_text = paste0("Start service: http://localhost:", port, "/index.html")
    message(message_text)
    ## TODO: change the port info in javascript
    runServer(host = "0.0.0.0", port = port, app = app)
}


