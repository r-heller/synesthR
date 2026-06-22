# syn_paint rejects non-score input

    Code
      syn_paint(list())
    Condition
      Error in `syn_paint()`:
      ! `score` must be a <prosody_score> object, not an empty list.

# syn_animate dual path: present builds, absent aborts

    Code
      syn_animate(sc)
    Condition
      Error in `syn_animate()`:
      ! `syn_animate()` requires the gganimate package.
      i Install it, or use `syn_paint()` for a still image.

