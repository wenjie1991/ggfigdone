response_fd_str_data = function(fo, req) {
    # print("response_fd_str_data")
    parsed_query = parse_url(req$QUERY_STRING)$query
    figure_id = parsed_query$id
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
    parsed_query = parse_url(req$QUERY_STRING)$query
    figure_id = parsed_query$id
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
    parsed_query = parse_url(req$QUERY_STRING)$query
    figure_id = parsed_query$id
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
    parsed_query = parse_url(req$QUERY_STRING)$query
    figure_id = parsed_query$id
    new_name = parsed_query$new_name
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
    parsed_query = parse_url(req$QUERY_STRING)$query
    figure_name = parsed_query$id
    width = as.numeric(parsed_query$width)
    height = as.numeric(parsed_query$height)
    units = parsed_query$units
    dpi = as.numeric(parsed_query$dpi)
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
    parsed_query = jsonlite::fromJSON(postdata)
    figure_name = parsed_query$id
    expr = parsed_query$gg_code
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
    parsed_query = parse_url(req$QUERY_STRING)$query
    figure_id = parsed_query$id
    fd_rm(figure_id, fo)
    list(
        status = 200L,
        headers = list('Content-Type' = "text/plain"),
        body = "OK"
    )
}

# Serve a static file
serveFile <- function(filepath) {
    # Read the file contents
    file_contents <- readChar(filepath, file.info(filepath)$size)

    list(
        status = 200L,
        headers = list("Content-Type" = "text/html"),
        body = file_contents
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
#' @param host Server host name or IP address; the default is "0.0.0.0".
#' @param port The port on which the server will run; the default is 8080.
#' @param llm_api_key The API key for the large language model service; the
#' default is NULL. When NULL, the service will not be available.
#' @param llm_api_url The URL for the OpenAI language model; the default is
#' "https://api.openai.com/v1/chat/completions".
#' @param llm_model The model to use for the large language model; the default
#' is "gpt-4o-mini".
#' @param llm_max_tokens The maximum number of tokens to generate; the default is 1000.
#' @param llm_temperature The temperature for the language model; the default is 0.5.
#' The temperature is a hyperparameter that controls the randomness of the
#' generated text. Lower temperatures will generate more predictable text, while
#' higher temperatures will generate more random text.
#' @param token A logical value indicating whether a token should be used to access the server.
#' @param auto_open A logical value indicating whether the server should be
#' opened in a web browser; the default is TRUE.
#' @return No return value, the function is called for its side effects.
#' @examples
#' \dontrun{
#' library(ggplot2)
#' ## Initialize the database
#' fo = fd_init("./fd_dir")
#' ## Draw a ggplot figure
#' g = ggplot(mtcars, aes(x=wt, y=mpg)) + geom_point()
#' 
#' ## Add the figure to the database
#' fd_add(name  = "fig1")
#' 
#' ## Start the server
#' fd_server("./fd_dir")
#' }
#' @export
fd_server = function(
    dir, 
    host = getOption("ggfigdone.host", "0.0.0.0"),
    port = getOption("ggfigdone.port", 8080),
    llm_api_key = getOption("ggfigdone.llm_api_key", NULL),
    llm_api_url = getOption("ggfigdone.llm_api_url", "https://api.openai.com/v1/chat/completions"),
    llm_model = getOption("ggfigdone.llm_model", "gpt-4o-mini"),
    llm_max_tokens = getOption("ggfigdone.llm_max_tokens", 1000),
    llm_temperature = getOption("ggfigdone.llm_temperature", 0.5),
    token = getOption("ggfigdone.token", TRUE),
    auto_open = getOption("ggfigdone.auto_open", FALSE)
) {

    ## Large language model configuration
    llm_config = 
        if (is.null(llm_api_key)) {
            message("The large language model service is not available.")
            NULL
        } else {
            list(
                api_url = llm_api_url,
                api_key = llm_api_key,
                model = llm_model,
                max_tokens = llm_max_tokens,
                temperature = llm_temperature
            )
        }

    ## Load the database
    fo = fd_load(dir)
    # print(fd_ls(fo))
    # print(format(fo))
    # on.exit(fd_save(fo))

    ## Directory of the web application
    www_dir = system.file("www", package = "ggfigdone")

    ## Token to access the server
    tok = 
        if (token) {
            uuid::UUIDgenerate()
        } else {
            ""
        }

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
            parsed_query = parse_url(req$QUERY_STRING)
            # print(parsed_query)

            if (token) {
                given_token = try(parsed_query$query$token)

                if (is(given_token, "try-error") | given_token != tok) {
                    return (serveFile(file.path(www_dir, "404-token.html")))
                }
            }

            if (path == "/fd") {
                serveFile(file.path(www_dir, "index.html"))
            } else if (path == "/fd_ls") {
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
            } else if (path == "/llm_config") {
                list(
                    status = 200L,
                    headers = list('Content-Type' = "application/json"),
                    body = toJSON(llm_config, auto_unbox = T)
                )
            } else {
                serveFile(file.path(www_dir, "404.html"))
            }
        },
        staticPaths = list(
            "/figure" = file.path(dir, "figures"),
            "/tmp" = file.path(dir, "tmp"),
            "/css" = file.path(www_dir, "css"),
            "/js" = file.path(www_dir, "js")
            # "/index.html" = file.path(www_dir, "index.html")
        )
    )

    # start the server
    url = paste0("http://", host, ":", port, "/fd") 
    if (token) {
        url = paste0(url, "?token=", tok)
    }
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


