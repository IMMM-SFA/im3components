# Title     : A demonstration R script
# Objective : Demonstrate R functionality when called as a component
# Created by: Chris R. Vernon
# Created on: 10/12/21

#' Add together two numbers that have been squared
#'
#' @param x An integer
#' @param y An integer
#' @return The sum of \code{x^2} and \code{y^2}
#' @examples
#' r_demo(x = 2, y = 5)
r_demo <- function(x, y) {

  square_x <- r_demo_square(x)
  square_y <- r_demo_square(y)

  return(square_x + square_y)
}


#' Return the square of a number
#'
#' @param x An integer
#' @return The square of \code{x}
#' @examples
#' r_demo_square(x = 2)
r_demo_square <- function(x) {
  return(x**2)
}
