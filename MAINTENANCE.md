# Maintenance review — 30 October 2026

## Scope and release criteria

Literary text in English, German, or French becomes a reproducible artistic
score, image, palette, and waveform. This increment requires input integrity,
portable optional-dependency tests, a clean source-package check, and working
installed text-to-media and app journeys. Scientific validation of the artistic
mapping is outside these criteria; README now makes that distinction explicit.

## Findings and completed work

- High, `R/read.R`: missing table/text entries were silently concatenated as the
  literal word NA, contaminating features. Missing values now fail explicitly.
- Medium, score/audio inputs: fractional seeds/rates were silently truncated;
  non-finite or overflowing values failed later. Validate before coercion.
- Medium, optional tests: dependency-dependent snapshots changed between
  machines; merely testing Python availability provisioned a runtime. Missing
  packages are now tested through mocked detection; Python execution requires
  an explicitly configured interpreter. Existing snapshot expectations remain.
- Medium, app: audio filenames exposed the session token, files survived session
  end, and re-synthesis reused a cacheable URL. Independent random filenames,
  content-based cache keys, and session-end cleanup fix these issues. Fractional
  seeds are rejected in the UI. Optional interpretation contacts its backend
  only when requested.
- Packaging: linked-worktree metadata is excluded from source archives.

## Verification

R 4.6.1, macOS arm64. Full source tests passed; deterministic optional-path suite
passed in 6.94 s and app lifecycle checks passed. Final build with vignettes
(56.06 s) and full `R CMD check --no-manual` (91.93 s): Status OK. Optional
ellmer, gm, cld3 and ffmpeg paths were not available; explicit Python tests skip
without a configured interpreter. No live model requests were made.

The final installed package produced repeatable scores and images for all three
languages, sample-exact WAV round trips at 8000 Hz, and refused to overwrite
existing files without permission. An initial overly strict R type comparison
failed because WAV reads return integer samples rather than numeric samples;
values, bit depth, and sample rate match exactly. Chromium verified initial
rendering, re-synthesis, fresh audio URL, actual RIFF response, and a PNG download.
The final app screenshot was visually inspected; no page or Shiny errors occurred.

## First use and roadmap

Install from the local checkout using README commands. Run
`syn_score(syn_read_text(syn_example_text("en"), lang = "en"))`, then `syn_paint()`,
`syn_write_wav()`, or `syn_run_app()` with the resulting score where appropriate.
Core workflows are locally ready. Remaining optional work: explicit CI jobs for
MuseScore, Python, and a local interpretation provider, plus multilingual human
evaluation of artistic mappings. No cross-platform, remote CI, CRAN, or hosted
operation is claimed. Review/integrate this local branch and run remote CI before
publication. No push or submission occurred.
