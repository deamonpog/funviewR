#' Analyze internal dependencies in R source files
#'
#' Parses multiple R files to identify function definitions and their internal
#' dependencies. Creates a comprehensive map of which functions call which other
#' functions within the analyzed codebase.
#'
#' @param file_paths Character vector of R file paths to analyze.
#'
#' @return A list with the following components:
#' \describe{
#'   \item{dependency_map}{Named list mapping function names to character vectors
#'     of their dependencies}
#'   \item{env}{Environment containing all parsed functions}
#'   \item{all_code_lines}{Character vector of all code lines from all files}
#'   \item{function_file_map}{Named list mapping function names to their source
#'     file paths}
#'   \item{duplicates}{List of functions defined in multiple files with their
#'     source locations}
#' }
#'
#' @details
#' This function uses \code{codetools::findGlobals()} to detect function calls
#' within function bodies. Only functions defined within the analyzed files are
#' tracked. External package functions and base R functions are not included in
#' the dependency map.
#'
#' @importFrom codetools findGlobals
#' 
#' @export
#'
#' @examples
#' # Create temporary R files for demonstration
#' temp_file1 <- tempfile(fileext = ".R")
#' temp_file2 <- tempfile(fileext = ".R")
#' 
#' # Write sample R code to temporary files
#' writeLines(c(
#'   "add_numbers <- function(a, b) {",
#'   "  a + b",
#'   "}",
#'   "",
#'   "calculate_sum <- function(x) {",
#'   "  add_numbers(x, 10)",
#'   "}"
#' ), temp_file1)
#' 
#' writeLines(c(
#'   "multiply <- function(a, b) {",
#'   "  a * b",
#'   "}",
#'   "",
#'   "process_data <- function(x) {",
#'   "  result <- add_numbers(x, 5)",
#'   "  multiply(result, 2)",
#'   "}"
#' ), temp_file2)
#' 
#' # Analyze the files
#' dep_info <- analyze_internal_dependencies_multi(c(temp_file1, temp_file2))
#' 
#' # View the dependency map
#' print(dep_info$dependency_map)
#' 
#' # Check for duplicate function definitions
#' if (length(dep_info$duplicates) > 0) {
#'   message("Warning: Functions defined in multiple files:")
#'   print(dep_info$duplicates)
#' }
#' 
#' # Clean up
#' unlink(c(temp_file1, temp_file2))
analyze_internal_dependencies_multi <- function(file_paths) {
  # Input validation
  if (missing(file_paths) || length(file_paths) == 0) {
    stop("'file_paths' must be a non-empty character vector")
  }
  
  if (!is.character(file_paths)) {
    stop("'file_paths' must be a character vector")
  }
  
  # Check that files exist
  missing_files <- file_paths[!file.exists(file_paths)]
  if (length(missing_files) > 0) {
    stop("The following files do not exist: ", 
         paste(missing_files, collapse = ", "))
  }
  
  all_code_lines <- character()
  all_exprs <- list()
  env <- new.env()
  defined_functions <- character()
  function_file_map <- list()
  duplicates <- list()

  for (file_path in file_paths) {
    code_lines <- readLines(file_path, warn = FALSE)
    code_text <- paste(code_lines, collapse = "\n")
    exprs <- tryCatch(parse(text = code_text), error = function(e) NULL)
    if (is.null(exprs)) next

    all_code_lines <- c(all_code_lines, code_lines)
    all_exprs <- c(all_exprs, as.list(exprs))

    for (expr in exprs) {
      if (is.call(expr) && (expr[[1]] == "<-" || expr[[1]] == "=")) {
        lhs <- expr[[2]]
        rhs <- expr[[3]]
        if (is.symbol(lhs) && is.call(rhs) && rhs[[1]] == "function") {
          fname <- as.character(lhs)
          ns_fname <- paste0(basename(file_path), "::", fname)
          if (!is.null(function_file_map[[fname]])) {
            duplicates[[fname]] <- unique(c(duplicates[[fname]], function_file_map[[fname]]))
          }
          defined_functions <- c(defined_functions, fname)
          function_file_map[[fname]] <- file_path
          assign(fname, eval(rhs), envir = env)
          assign(ns_fname, eval(rhs), envir = env)
        }
      }
    }
  }

  dependency_map <- list()
  unique_functions <- unique(defined_functions)
  for (fname in unique_functions) {
    f <- get(fname, envir = env)
    if (is.function(f)) {
      called <- codetools::findGlobals(f, merge = FALSE)$functions
      internal_calls <- intersect(called, unique_functions)
      dependency_map[[fname]] <- sort(unique(internal_calls))
    }
  }

  list(
    dependency_map = dependency_map,
    env = env,
    all_code_lines = all_code_lines,
    function_file_map = function_file_map,
    duplicates = duplicates
  )
}
