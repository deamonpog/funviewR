# funviewR

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
[![R](https://img.shields.io/badge/R-%3E%3D%203.5.0-blue)](https://www.r-project.org/)
[![](https://cranlogs.r-pkg.org/badges/funviewR)](https://cran.rstudio.com/web/packages/funviewR/index.html)

**funviewR** is an R package that analyzes R source code to detect function definitions and internal dependencies, then visualizes them as interactive network graphs.

## Features

- 📊 **Analyze R code dependencies** - Automatically detect function definitions and calls
- 🔍 **Multi-file & directory support** - Analyze multiple R files and directories together
- 🤖 **Auto-detection** - Automatically detects whether paths are files or directories
- 📈 **Interactive visualization** - Create beautiful dependency graphs with `visNetwork`
- 🔧 **Detailed tooltips** - View function arguments, return values, and documentation
- 🎯 **Smart layout** - Hierarchical graph layout with most-connected nodes centered
- ⚠️ **Duplicate detection** - Identify functions defined in multiple files
- ⚡ **One-line plotting** - Quick visualization with `plot_dependency_graph()`

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

### Quick Start (One-Line Solution)

The easiest way to visualize dependencies:

```r
library(funviewR)

# Analyze files or directories - auto-detects which is which!
plot_dependency_graph(c("R/", "analysis.R", "tests/"))

# Single directory
plot_dependency_graph("R/")

# Specific files
plot_dependency_graph(c("script1.R", "script2.R"))

# With options
plot_dependency_graph("src/", 
                      recursive = TRUE, 
                      include_disconnected = FALSE)
```

### Advanced Usage (Two-Step Process)

For more control and access to analysis data:

```r
library(funviewR)

# Step 1: Analyze files
file_paths <- c("path/to/your/script.R")
dep_info <- analyze_internal_dependencies_multi(file_paths)

# Step 2: Create visualization
plot_interactive_dependency_graph(dep_info)
```

### Working with Directories

```r
# Get all R files from a directory
files <- get_r_files("R/")

# Get R files recursively
files <- get_r_files("R/", recursive = TRUE)

# Then analyze
dep_info <- analyze_internal_dependencies_multi(files)
graph <- plot_interactive_dependency_graph(dep_info)
```

### Analyzing Multiple Sources

```r
# Mix files and directories - automatically detected!
plot_dependency_graph(c(
  "R/core/",
  "main.R",
  "R/utils/",
  "tests/",
  "helpers.R"
), recursive = TRUE)
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
- igraph
- htmltools
- magrittr

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the GNU General Public License v3.0

## Author

**Chathura Jayalath**
- Email: acj.chathura@gmail.com

## Acknowledgments

- Built with [visNetwork](https://github.com/datastorm-open/visNetwork) for interactive graph visualization
- Uses R's [codetools](https://cran.r-project.org/package=codetools) for dependency analysis
- Leverages [igraph](https://igraph.org/r/) for graph algorithms and distance calculations
- Uses [htmltools](https://github.com/rstudio/htmltools) for safe HTML rendering
- Powered by [magrittr](https://magrittr.tidyverse.org/) pipe operator

