#' Analyze internal dependencies in R source files
#'
#' @param file_paths Character vector of R file paths
#' @return A list with dependency_map, env, all_code_lines, function_file_map, duplicates
#' @export
analyze_internal_dependencies_multi <- function(file_paths) {
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
