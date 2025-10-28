# funviewR

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
[![R](https://img.shields.io/badge/R-%3E%3D%203.5.0-blue)](https://www.r-project.org/)

**funviewR** is an R package that analyzes R source code to detect function definitions and internal dependencies, then visualizes them as interactive network graphs.

## Features

- 📊 **Analyze R code dependencies** - Automatically detect function definitions and calls
- 🔍 **Multi-file support** - Analyze multiple R files together
- 📈 **Interactive visualization** - Create beautiful dependency graphs with `visNetwork`
- 🔧 **Detailed tooltips** - View function arguments, return values, and documentation
- 🎯 **Smart layout** - Hierarchical graph layout with most-connected nodes centered
- ⚠️ **Duplicate detection** - Identify functions defined in multiple files

## Installation

### From GitHub

You can install the development version from GitHub:

```r
# Install remotes if you don't have it
install.packages("remotes")

# Install funviewR from GitHub
remotes::install_github("deamonpog/funviewR")
```

## Usage

### Basic Example

```r
library(funviewR)

# Analyze a single R file
file_paths <- c("path/to/your/script.R")
dep_info <- analyze_internal_dependencies_multi(file_paths)

# Create an interactive dependency graph
plot_interactive_dependency_graph(dep_info)
```

### Analyzing Multiple Files

```r
# Analyze multiple R files in a directory
file_paths <- list.files("R/", pattern = "\\.R$", full.names = TRUE)
dep_info <- analyze_internal_dependencies_multi(file_paths)

# Plot the graph
graph <- plot_interactive_dependency_graph(dep_info, include_disconnected = FALSE)
graph
```

### Working with the Results

The `analyze_internal_dependencies_multi()` function returns a list containing:

- `dependency_map`: A list mapping each function to its dependencies
- `env`: Environment containing all defined functions
- `all_code_lines`: All code lines from analyzed files
- `function_file_map`: Maps function names to their source files
- `duplicates`: Lists functions defined in multiple files

```r
# Access the dependency map
dep_info$dependency_map

# Check for duplicate function definitions
if (length(dep_info$duplicates) > 0) {
  print("Warning: Duplicate functions found:")
  print(dep_info$duplicates)
}
```

## Example Output

The interactive graph provides:

- **Blue boxes**: Defined functions with full metadata
- **Gray ellipses**: External or undefined functions
- **Arrows**: Function call relationships
- **Tooltips**: Hover over nodes to see:
  - Function arguments
  - Return values
  - Source file
  - Documentation (if available)

## Requirements

- R >= 3.5.0
- codetools
- visNetwork
- htmlwidgets

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the GNU General Public License v3.0 - see the [LICENSE](LICENSE) file for details.

## Author

**Chathura Jayalath**
- Email: acj.chathura@gmail.com

## Acknowledgments

- Built with [visNetwork](https://github.com/datastorm-open/visNetwork) for interactive graph visualization
- Uses R's [codetools](https://cran.r-project.org/package=codetools) for dependency analysis
