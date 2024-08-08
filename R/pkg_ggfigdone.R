#' ggfigdone
#' 
#' ggfigdone: Manage & Modify ggplot figures easily
#' 
#' When preparing a presentation or report, it is often necessary to manage a substantial number of ggplot figures. 
#' Adjustments such as changing the figure size, modifying titles, labels, and themes may be required. 
#' Returning to the original code to implement these changes can be inconvenient. 
#' This package offers a straightforward method for managing ggplot figures. 
#' Figures can be easily added to the database and subsequently updated using either a GUI (graphical user interface) and/or CLI (command line interface).
#'
#' @name ggfigdone
#' @import ggplot2
#' @import httpuv
#' @import httr
#' @importFrom jsonlite fromJSON toJSON
#' @importFrom filelock lock unlock
#' @importFrom utils browseURL capture.output str
"_PACKAGE"
