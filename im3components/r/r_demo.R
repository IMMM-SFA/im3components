# Title     : A demonstration R script
# Objective : Demonstrate R functionality when called as a component
# Created by: Chris R. Vernon
# Created on: 10/12/21

#' Add together two numbers
#'
#' @param x An integer
#' @param y An integer
#' @return The sum of \code{x} and \code{y}
#' @examples
#' demo(x = 2, y = 5)
demo <- function(x, y) {
  return(x + y)
}
