
<!-- README.md is generated from README.Rmd. Please edit that file -->

# synesthR <img src="man/figures/logo.png" align="right" height="139" alt="synesthR hex logo" />

<!-- badges: start -->

[![R-CMD-check](https://github.com/r-heller/synesthR/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/r-heller/synesthR/actions/workflows/R-CMD-check.yaml)
[![Codecov test
coverage](https://codecov.io/gh/r-heller/synesthR/graph/badge.svg)](https://app.codecov.io/gh/r-heller/synesthR)
[![Lifecycle:
experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
<!-- badges: end -->

**synesthR** turns literary text (German, English, French) into
synchronized generative images and music. It extracts a sentence-level
sentiment arc, lexical diversity, rhythm, and punctuation density into a
single *prosody score*, then maps that score deterministically onto both
a still image and a synchronized audio waveform — so the picture and the
music are two views of the same analysis. Colour palettes and `ggplot2`
themes can be extracted from text, images, or audio through one
interface, and an optional local-LLM layer can interpret the result.

## How it works

One shared score, rendered three ways — the same numbers become a picture, a
piece of audio, and a colour palette:

<img src="man/figures/README-workflow.png" alt="synesthR workflow: a text is read into a prosody score, whose sentiment arc is mapped deterministically onto a generative image, a synchronized audio waveform, and a colour palette." width="100%" />

## Installation

``` r
# install.packages("pak")
pak::pak("r-heller/synesthR")
```

## Usage

``` r
library(synesthR)

text  <- syn_read_text(syn_example_text("en"), lang = "en")
score <- syn_score(text)
score
#> <prosody_score> — 6 sentences, lang "en"

# the image and the audio are two views of the same score
syn_paint(score)
```

<img src="man/figures/README-demo-1.png" alt="A generative image rendered from the example text." width="100%" />

``` r
wav <- syn_write_wav(score, tempfile(fileext = ".wav"))

# a palette and matching ggplot2 theme, from the same score
syn_palette(score)
#> <syn_palette> - 5 colours, cool, from prosody_score
#> "#294D00" background
#> "#207900" shadow
#> "#00A65D" mid
#> "#00D5A4" accent
#> "#3BFFEB" highlight
```

The core (`read -> score -> map -> paint/play/palette/media`) is pure R,
deterministic given `(text, seed)`, and requires no external software.
Optional extensions (image/audio palettes via `magick`/`seewave`,
animation via `gganimate`, engraved scores via `gm`, a local LLM via
`ellmer`, and Python interop via `reticulate`) live in `Suggests` and
degrade gracefully when absent.

## License

MIT © Raban Heller
