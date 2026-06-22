# syn_palette image method aborts cleanly when magick is absent

    Code
      syn_palette(fake)
    Condition
      Error in `syn_palette()`:
      ! Extracting a palette from an image requires the magick package.
      i Install it with `install.packages("magick")`.

# print.syn_palette is stable

    Code
      print(syn_palette(sc, n = 5L))
    Message
      <syn_palette> - 5 colours, mixed, from prosody_score
      "#484700" background
      "#4F7400" shadow
      "#4AA33B" mid
      "#3DD48E" accent
      "#44FFDA" highlight

