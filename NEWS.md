# synesthR 0.2.0

* Prepare the package for CRAN: maintainer address at Ulm University,
  `Language` field, an extended spelling word list and updated
  `cran-comments.md`.
* Add examples to every exported function. Examples that need a local
  language model or a Python installation are not run; those for optional
  packages ('gganimate', 'gm') run only when the package is installed.
* Describe the bundled example passages accurately: they were written for
  this package and are distributed under its licence.
* Skip the test that probes for an installed 'ffmpeg' on CRAN.

# synesthR 0.1.0

* Initial release. Text -> shared feature score -> synchronized still image
  (`syn_paint()`) and self-contained audio (`syn_play()`), for German, English,
  and French input.
