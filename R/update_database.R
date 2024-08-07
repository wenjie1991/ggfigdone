## Following code is used to update the database with new data structures

## From no version to version 1
transform_db_v02v1 <- function(dir) {
    ## Lock before updating
    lock = lock(file.path(dir, "/db.lock"), exclusive = FALSE)

    ## Get fig id 
    env = readr::read_rds(file.path(dir, "env.rds"))

    ## Create a new environment
    new_env = new.env()

    ## Update the database
    lapply(names(env), function(fig_id) {
        fig_id = names(env)[1]
        ## Extract the data from ggplot object
        x = env[[fig_id]]
        names(x)
        x$canvas_options
        g = x$g_origin
        d = g$data

        ## Extract the ggplot code
        # code_origin = fd_extract_ggplot_code(g)

        code_origin = "g"

        ## Append the updating history history code to the original code
        update_history = x$update_history
        code_updated = paste(update_history, collapse = " + ")
        if (code_updated != "") {
            code_updated = paste0(code_origin, " + ", code_updated)
        } else {
            code_updated = code_origin
        }

        ## Create a new fig object
        ## Remove update_history
        x$update_history = NULL 

        x$code_updated = code_updated
        x$code_origin = code_origin

        ## Add new fig object to the new environment
        code_run = paste0("ggplot2::ggplot(d) + ", code_updated)
        g_updated = eval(parse(text = code_run))
        new_env[[fig_id]] = x
    })

    ## Save the new environment to the disk
    readr::write_rds(new_env, file.path(dir, "env.rds"))
    writeLines("v1", file.path(dir, "version.txt"))

    unlock(lock)
}

