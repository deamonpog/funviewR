#' Get all parsed expressions from an R file
#'
#' @param file_path Path to R file
#' @return List of expressions or NULL
#' @export
get_all_expressions <- function(file_path) {
  code_lines <- readLines(file_path, warn = FALSE)
  code_text <- paste(code_lines, collapse = "\n")
  exprs <- tryCatch(parse(text = code_text), error = function(e) NULL)
  if (!is.null(exprs)) as.list(exprs) else NULL
}

#' Get all R files from a directory
#'
#' @param directory Path to directory containing R files
#' @param recursive If TRUE, search subdirectories recursively. Default is FALSE.
#' @param pattern Regular expression pattern for filenames. Default is "\\.R$" (files ending in .R)
#' @return Character vector of full paths to R files
#' @export
#' @examples
#' \dontrun{
#' # Get all R files in a directory
#' files <- get_r_files("path/to/directory")
#' 
#' # Search recursively in subdirectories
#' files <- get_r_files("path/to/directory", recursive = TRUE)
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
#' @param include_disconnected If FALSE, exclude isolated nodes from the graph.
#'   Default is TRUE.
#' @param recursive If directories are encountered, search subdirectories recursively.
#'   Default is FALSE.
#' @return A visNetwork HTML widget displaying the dependency graph
#' @export
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
