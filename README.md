# ggfigdone: Manage ggplot figures using ggfigdone

## Description

When you prepare a presentation or a report, you often need to manage a large number of ggplot figures. 
You need to change the figure size, modify the title, label, themes, etc. 
It is inconvinient to go back to the original code to make these changes.
This package provides a simple way to manage ggplot figures. 
You can easily add the figure to the database and update them later using CLI (command line interface) or GUI (graphical user interface).

## Installation

Package is being developed ...

TBD

## Demo

### Initialize the database

First, you need to initialize the database and add figures to it.


```r
library(ggfigdone)

## Initial ggfigdone database using `fd_init`
## The database location is `./fd_dir`
fo = fd_init("./fd_dir")

## Draw a ggplot figure
g = ggplot(mtcars, aes(x=wt, y=mpg)) + geom_point()

## Add the figure to the database
fd_add(g = g, name  = "fig1", fo, overwrite = T)

## Add the same figure with a different name
fd_add(g = g, name  = "fig2", fo, overwrite = T)

## Save the database
fd_save(fo)

```

### Manage the figures in browser

Then you can start the server and open the browser to manage the figures.

```r
## Load the database
fo = fd_load("./fd_dir")

## Start the server and open the browser
fd_server("./fd_dir")
```


## Contribution

This package is being developed. Feel free to contribute to the package by sending pull requests or creating issues.

## License

MIT License
