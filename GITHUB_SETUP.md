# GitHub Setup Instructions

Follow these steps to host your funviewR package on GitHub:

## 1. Initialize Git Repository

Open a terminal in the `funviewR` directory and run:

```powershell
cd d:\PROJECTS\RCodeAnalyzer\funviewR
git init
git add .
git commit -m "Initial commit: funviewR package with GPL-3 license"
```

## 2. Create GitHub Repository

1. Go to https://github.com/new
2. Repository name: `funviewR`
3. Description: "R package to visualize function call dependencies in R source code"
4. Make it **Public**
5. **DO NOT** initialize with README, .gitignore, or license (we already have these)
6. Click "Create repository"

## 3. Link Local Repository to GitHub

Replace `yourusername` with your actual GitHub username:

```powershell
git remote add origin https://github.com/yourusername/funviewR.git
git branch -M main
git push -u origin main
```

## 4. Update README.md

After creating the repository, update the installation instruction in `README.md`:

Replace:
```r
remotes::install_github("yourusername/funviewR")
```

With your actual GitHub username:
```r
remotes::install_github("your-actual-username/funviewR")
```

Then commit and push:

```powershell
git add README.md
git commit -m "Update installation instructions with correct GitHub username"
git push
```

## 5. Add GitHub Topics (Optional but Recommended)

On your GitHub repository page:
1. Click the gear icon next to "About"
2. Add topics: `r`, `r-package`, `visualization`, `dependency-graph`, `code-analysis`, `static-analysis`
3. Save changes

## 6. Enable GitHub Pages for Documentation (Optional)

You can create a pkgdown site:

```r
# Install pkgdown
install.packages("pkgdown")

# Build site
pkgdown::build_site()

# Commit and push the docs folder
```

Then enable GitHub Pages in repository Settings > Pages > Source: main branch > /docs folder

## 7. Add Badges to README (Optional)

You can add additional badges like:
- GitHub release version
- R CMD check status
- Code coverage

## Verification

After pushing, verify your repository includes:
- [x] DESCRIPTION (with GPL-3 license and dependencies)
- [x] LICENSE
- [x] README.md
- [x] NAMESPACE
- [x] .gitignore
- [x] .Rbuildignore
- [x] R/ directory with source files

## Installation Test

After pushing to GitHub, test installation with:

```r
remotes::install_github("your-actual-username/funviewR")
library(funviewR)
?analyze_internal_dependencies_multi
```

## Next Steps

Consider adding:
1. **CONTRIBUTING.md** - Guidelines for contributors
2. **NEWS.md** - Changelog for version updates
3. **tests/** directory - Unit tests with testthat
4. **vignettes/** - Long-form documentation
5. **GitHub Actions** - Automated R CMD check on push/PR
6. **CODE_OF_CONDUCT.md** - Community guidelines

## Licensing Note

Your package is now GPL-3 licensed, which means:
- ✅ Anyone can use, modify, and distribute your code
- ✅ Modifications must also be GPL-3
- ✅ Source code must be made available
- ✅ Perfect for open-source collaboration
