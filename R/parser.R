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
