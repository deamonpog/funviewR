#' Get all parsed expressions from an R file
#'
#' Reads an R source file and parses it into a list of expressions. This is a
#' utility function primarily used internally by
#' \code{\link{analyze_internal_dependencies_multi}}.
#'
#' @param file_path Character string. Path to an R file to parse.
#'
#' @return A list of parsed expressions, or \code{NULL} if parsing fails.
#'
#' @export
#'
#' @examples
#' # Create a temporary R file
#' temp_file <- tempfile(fileext = ".R")
#' writeLines(c(
#'   "my_function <- function(x) { x + 1 }",
#'   "another_function <- function(y) { y * 2 }"
#' ), temp_file)
#' 
#' # Parse the file
#' exprs <- get_all_expressions(temp_file)
#' if (!is.null(exprs)) {
#'   print(length(exprs))
#' }
#' 
#' # Clean up
#' unlink(temp_file)
get_all_expressions <- function(file_path) {
  code_lines <- readLines(file_path, warn = FALSE)
  code_text <- paste(code_lines, collapse = "\n")
  exprs <- tryCatch(parse(text = code_text), error = function(e) NULL)
  if (!is.null(exprs)) as.list(exprs) else NULL
}

#' Get all R files from a directory
#'
#' Recursively or non-recursively searches a directory for R source files
#' matching a specified pattern. Returns full paths suitable for use with
#' \code{\link{analyze_internal_dependencies_multi}}.
#'
#' @param directory Character string. Path to directory containing R files.
#' @param recursive Logical. If \code{TRUE}, search subdirectories recursively.
#'   Default is \code{FALSE}.
#' @param pattern Character string. Regular expression pattern for filenames.
#'   Default is \code{"\\\\.R$"} (files ending in .R, case insensitive).
#'
#' @return Character vector of full paths to R files found in the directory.
#'   Returns an empty vector with a warning if no files are found.
#'
#' @export
#'
#' @examples
#' # Create a temporary directory with R files
#' temp_dir <- tempfile()
#' dir.create(temp_dir)
#' 
#' # Create some R files
#' writeLines("f1 <- function(x) { x + 1 }", file.path(temp_dir, "file1.R"))
#' writeLines("f2 <- function(y) { y * 2 }", file.path(temp_dir, "file2.R"))
#' 
#' # Get all R files in the directory
#' files <- get_r_files(temp_dir)
#' print(files)
#' 
#' # Create subdirectory
#' subdir <- file.path(temp_dir, "subdir")
#' dir.create(subdir)
#' writeLines("f3 <- function(z) { z - 1 }", file.path(subdir, "file3.R"))
#' 
#' # Search recursively
#' files_recursive <- get_r_files(temp_dir, recursive = TRUE)
#' print(files_recursive)
#' 
#' # Clean up
#' unlink(temp_dir, recursive = TRUE)
get_r_files <- function(directory, recursive = FALSE, pattern = "\\.R$") {
  if (!dir.exists(directory)) {
    stop("Directory does not exist: ", directory)
  }
  
  files <- list.files(
    path = directory,
    pattern = pattern,
    full.names = TRUE,
    recursive = recursive,
    ignore.case = TRUE
  )
  
  if (length(files) == 0) {
    warning("No R files found in directory: ", directory)
  }
  
  return(files)
}

#' Analyze and plot R code dependencies in one step
#'
#' Convenience function that analyzes R files and directly returns the
#' interactive dependency graph without exposing intermediate analysis results.
#' Automatically detects whether paths are files or directories.
#'
#' @param file_paths Character vector of R file paths, directory paths, or a mix.
#'   The function automatically detects files vs directories.
#' @param include_disconnected Logical. If \code{FALSE}, exclude isolated nodes
#'   (functions with no dependencies) from the graph. Default is \code{TRUE}.
#' @param recursive Logical. If directories are encountered, search subdirectories
#'   recursively. Default is \code{FALSE}.
#'
#' @return A \code{visNetwork} HTML widget displaying the interactive dependency
#'   graph. The graph can be saved using \code{htmlwidgets::saveWidget()}.
#'
#' @details
#' This is a convenience wrapper around \code{\link{analyze_internal_dependencies_multi}}
#' and \code{\link{plot_interactive_dependency_graph}}. It automatically:
#' \itemize{
#'   \item Detects whether each path is a file or directory
#'   \item Collects all R files from directories
#'   \item Analyzes function dependencies
#'   \item Creates an interactive visualization
#' }
#'
#' @export
#'
#' @examples
#' # Create temporary directory and files
#' temp_dir <- tempfile()
#' dir.create(temp_dir)
#' 
#' # Create sample R files
#' writeLines(c(
#'   "add <- function(a, b) { a + b }",
#'   "calc <- function(x) { add(x, 10) }"
#' ), file.path(temp_dir, "math.R"))
#' 
#' writeLines(c(
#'   "process <- function(data) { add(data, 5) }"
#' ), file.path(temp_dir, "process.R"))
#' 
#' # Analyze and plot - single file
#' graph <- plot_dependency_graph(file.path(temp_dir, "math.R"))
#' 
#' # Analyze directory
#' graph <- plot_dependency_graph(temp_dir)
#' 
#' # Exclude disconnected nodes
#' graph <- plot_dependency_graph(temp_dir, include_disconnected = FALSE)
#' 
#' # Clean up
#' unlink(temp_dir, recursive = TRUE)
plot_dependency_graph <- function(file_paths, 
                                  include_disconnected = TRUE,
                                  recursive = FALSE) {
  all_files <- character()
  
  # Auto-detect files vs directories
  for (path in file_paths) {
    if (dir.exists(path)) {
      # It's a directory - get all R files
      files_in_dir <- get_r_files(path, recursive = recursive)
      all_files <- c(all_files, files_in_dir)
    } else if (file.exists(path)) {
      # It's a file - add directly
      all_files <- c(all_files, path)
    } else {
      warning("Path does not exist: ", path)
    }
  }
  
  file_paths <- unique(all_files)
  
  if (length(file_paths) == 0) {
    stop("No valid R files found to analyze")
  }
  
  # Analyze dependencies
  dep_info <- analyze_internal_dependencies_multi(file_paths)
  
  # Create and return the plot
  plot_interactive_dependency_graph(dep_info, include_disconnected)
}
