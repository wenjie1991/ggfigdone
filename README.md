
<div align="center">
<img src="https://github.com/user-attachments/assets/4d3beba4-04e2-41e2-8645-0887cbde4b5c" width="240" /> 
</div>


# ggfigdone: Manage ggplot figures using ggfigdone
[![R](https://github.com/wenjie1991/ggfigdone/actions/workflows/r.yml/badge.svg)](https://github.com/wenjie1991/ggfigdone/actions/workflows/r.yml)


## Description

When you prepare a presentation or a report, you often need to manage a large number of ggplot figures. 
You need to change the figure size, modify the title, label, themes, etc. 
It is inconvinient to go back to the original code to make these changes.
This package provides a simple way to manage ggplot figures. 
You can easily add the figure to the database and update them later using CLI (command line interface) or GUI (graphical user interface).

![ggfigdone_demo](https://github.com/user-attachments/assets/a0d4d01d-105a-4fc0-bda5-c7cc3e6dbd48)

## Installation

Install the development version from GitHub:

```r
# install.packages("remotes")
remotes::install_github("wenjie1991/ggfigdone")
```

## Demo

### Initialize the database

First, you need to initialize the database and add figures to it.

Next time, you only need to load the database to add more figures or update the existing figures.


```r
library(ggfigdone)
library(ggplot2)

## Initial ggfigdone database using `fd_init`
## The database location is `./fd_dir`
## Load existing database using `fd_load("./fd_dir")`
fo = fd_init("./fd_dir")

## Draw a ggplot figure
g = ggplot(mtcars, aes(x=wt, y=mpg)) + geom_point()

## Add the figure to the database
## The last plot is added to the last initialized/loaded database
fd_add(name  = "fig1")

## Add the same figure with a different name
## You can specify the ggplot object and database name
fd_add(g = g, name  = "fig2", fo)

## The hard disk database is automatically updated, no need to save operations.
```

### Manage the figures in browser

Then you can start the server and open the browser to manage the figures.

```r
## To start the server, provide the database location 
fd_server("./fd_dir")

## Open the browser and go to http://localhost:8080/index.html
```

## Contribution

This package is being developed. Feel free to contribute to the package by sending pull requests or creating issues.

## License

MIT License
