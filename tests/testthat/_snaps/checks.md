# .check_string rejects non-strings

    Code
      .check_string(1L)
    Condition
      Error:
      ! `1L` must be a single non-missing string, not an integer.

---

    Code
      .check_string(c("a", "b"))
    Condition
      Error:
      ! `c("a", "b")` must be a single non-missing string, not a character vector.

---

    Code
      .check_string(NA_character_)
    Condition
      Error:
      ! `NA_character_` must be a single non-missing string, not a character `NA`.

# .check_flag rejects non-flags

    Code
      .check_flag("yes")
    Condition
      Error:
      ! `"yes"` must be a single `TRUE` or `FALSE`, not a string.

---

    Code
      .check_flag(c(TRUE, FALSE))
    Condition
      Error:
      ! `c(TRUE, FALSE)` must be a single `TRUE` or `FALSE`, not a logical vector.

---

    Code
      .check_flag(NA)
    Condition
      Error:
      ! `NA` must be a single `TRUE` or `FALSE`, not `NA`.

# .check_class validates inheritance

    Code
      .check_class(list(), "prosody_score")
    Condition
      Error:
      ! `list()` must be a <prosody_score> object, not an empty list.

# .check_choice validates and normalises a fixed choice

    Code
      .check_choice("xx", c("de", "en", "fr"))
    Condition
      Error:
      ! `"xx"` must be one of "de", "en", or "fr".
      x You supplied "xx".

