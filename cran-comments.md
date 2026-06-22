## R CMD check results

0 errors | 0 warnings | 0 notes

* This is a new submission.

## Notes

* All optional functionality (image/audio palettes, animation, engraved
  scores, local-LLM assist, Python interop, CLI tools) lives in `Suggests`
  and is guarded with `requireNamespace()`; the package passes
  `R CMD check --as-cran` with every optional package and external tool
  absent.
* Examples that require a network service or external software are wrapped
  in `\donttest{}` / `@examplesIf interactive()`.
