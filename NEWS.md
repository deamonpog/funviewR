# funviewR 0.1.1

## Bug Fixes

* Fixed regex error when analyzing functions with special characters in names (e.g., operators like `%+%`, `.`, `[`)
* Added proper escaping of function names in grep patterns to prevent "Invalid character range" errors

## New Features

* Added cycle detection using strongly connected components (SCC)
* Functions participating in dependency cycles are now highlighted with red borders
* Cycle information added to node tooltips
* Self-referential functions (recursive calls) are properly identified

# funviewR 0.1.0

## Initial Release

* First public release of funviewR
* Analyze R source code for function dependencies across multiple files
* Interactive visualization with visNetwork
* Support for multi-file and multi-directory analysis
* Automatic file/directory detection
* New convenience function `plot_dependency_graph()` for one-line visualization
* Helper function `get_r_files()` to gather R files from directories
* Duplicate function detection
* Detailed tooltips with function metadata (arguments, return values, documentation)
* Color-coded nodes by distance from most-connected function
* Optional recursive directory search
* GPL-3 license
