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
    # print("response_fd_download_pdf")
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

response_fd_ls = function(fo) {
    # print("response_fd_ls")
    list(
        status = 200L,
        headers = list('Content-Type' = "application/json"),
        body = toJSON(fd_ls(fo), auto_unbox = T)
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

#' Initiates a server for ggfigdone
#'
#' This function initiates a server for ggfigdone, which can be accessed through a web browser.
#' The web application enables users to manage and modify ggplot figures with ease.
#' Users have the ability to:
#' - Update the ggplot code by adding new components.
#' - Adjust the figure size.
#' - Download the figure as a PDF.
#' - Download the data used to create the figure.
#' 
#' By default the function will open a web browser to access the server.
#'
#' You can configure the web browser by setting the options:
#' 
#' ```{r}
#' options(browser = "firefox")  # Set Firefox as the default
#' ```
#' 
#' @param dir The directory of the ggfigdone database.
#' @param host The host on which the server will run; the default is '0.0.0.0'.
#' @param port The port on which the server will run; the default is 8080.
#' @param auto_open A logical value indicating whether the server should be opened in a web browser; the default is TRUE.
#' @return No return value, the function is called for its side effects.
#' @export
fd_server = function(dir, host = '0.0.0.0', port = 8080, auto_open = TRUE) {
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
    url = paste0("http://", host, ":", port, "/index.html")
    message_text = paste0("Start service: ", url) 
    message(message_text)
    # runServer(host = "0.0.0.0", port = port, app = app)
    server <- startServer(host = host, port = port, app = app)
    if (auto_open) {
        browseURL(url)
    }
    on.exit(stopServer(server))
    service(0)
}


