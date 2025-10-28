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
#' \dontrun{
#' # Parse a single file
#' exprs <- get_all_expressions("my_script.R")
#' if (!is.null(exprs)) {
#'   print(length(exprs))
#' }
#' }
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
#' \dontrun{
#' # Get all R files in a directory
#' files <- get_r_files("R/")
#' 
#' # Search recursively in subdirectories
#' files <- get_r_files("src/", recursive = TRUE)
#' 
#' # Use with analyze_internal_dependencies_multi
#' files <- get_r_files("R/")
#' dep_info <- analyze_internal_dependencies_multi(files)
#' }
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
#' \dontrun{
#' # Analyze specific files
#' plot_dependency_graph(c("script1.R", "script2.R"))
#'
#' # Analyze all R files in a directory
#' plot_dependency_graph("R/")
#'
#' # Mix files and directories (auto-detected)
#' plot_dependency_graph(c("R/", "analysis.R", "tests/", "main.R"))
#'
#' # Analyze recursively and exclude disconnected nodes
#' plot_dependency_graph("R/", recursive = TRUE, 
#'                       include_disconnected = FALSE)
#'
#' # Save the output
#' graph <- plot_dependency_graph("R/")
#' htmlwidgets::saveWidget(graph, "dependencies.html")
#' }
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
