# syn_read_text errors on a missing text column

    Code
      syn_read_text(tibble::tibble(nope = "hi"), lang = "en")
    Condition
      Error:
      ! Column "text" not found in the supplied data frame.
      i Pass `text_col` to name the text column.

# syn_read_text errors on unsupported input type

    Code
      syn_read_text(42L, lang = "en")
    Condition
      Error:
      ! `x` must be a string, a file path, or a data frame.
      x You supplied an integer.

# .detect_lang validates an explicit lang

    Code
      .detect_lang("text", "xx")
    Condition
      Error:
      ! `lang` must be one of "de", "en", or "fr".
      x You supplied "xx".

# auto-detect path: present uses cld3, absent aborts

    Code
      syn_read_text("some text", lang = NULL)
    Condition
      Error:
      ! Cannot auto-detect language: package cld3 is not installed.
      i Install cld3, or pass `lang` explicitly ("de", "en", or "fr").

