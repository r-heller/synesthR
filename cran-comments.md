## Submission

This is a new submission.

## Test environments

* local: macOS (aarch64), R 4.6.1, `R CMD check --as-cran --no-manual`
  (the PDF manual was built locally with TinyTeX (TeX Live 2026) via
  `R CMD Rd2pdf` without errors; the check run itself used `--no-manual`)
* GitHub Actions: macos-latest (release), windows-latest (release),
  ubuntu-latest (devel, release, oldrel-1), with `--as-cran`

## R CMD check results

0 errors | 0 warnings | 1 note

* checking CRAN incoming feasibility ... NOTE
  New submission

## Notes

* All optional functionality (image and audio palettes, animation, engraved
  scores, local-LLM assistance, Python interoperability and command-line
  tools) lives in `Suggests` and is guarded with `requireNamespace()` or a
  tool check; the package passes `R CMD check --as-cran` with every optional
  package and external tool absent.
* Video export is not available in this version: `syn_export_video()` always
  signals an informative error, whether or not 'ffmpeg' is installed.
* Examples that need a running local language model (Ollama) or a Python
  installation with 'numpy' are wrapped in `\dontrun{}` with a comment
  explaining why. Examples for the optional packages 'gganimate' and 'gm'
  run only when those packages are installed.
* The bundled example passages (`inst/extdata`) were written for this package
  and are distributed under its MIT licence.
