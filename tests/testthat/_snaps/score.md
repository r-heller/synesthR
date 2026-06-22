# syn_score rejects non-read_text input

    Code
      syn_score(list(a = 1))
    Condition
      Error:
      ! `text` must be a tibble from `syn_read_text()`.
      i It needs sentence_id and sentence columns.

# golden snapshot of the en sample feature tibble (reproducibility contract)

    Code
      as.data.frame(round_df(sc$features))
    Output
        sentence_id
      1           1
      2           2
      3           3
      4           4
      5           5
      6           6
                                                                                                          sentence
      1                                                                The morning broke quietly over the harbour.
      2                                Grey water lay still against the stones, and the boats had not yet stirred.
      3                                     A single gull crossed the pale sky, calling once, then falling silent.
      4                                       She watched from the window and felt the day gather its slow weight.
      5   Later the wind would rise, and the colours would sharpen, and the small town would remember how to move.
      6 But for now there was only the hush, the patient light, and the long breath before everything began again.
        valence length lex_diversity punct_density
      1      -1      7        0.8571        0.0233
      2       0     14        0.9286        0.0267
      3      -1     12        1.0000        0.0429
      4       0     13        0.9231        0.0147
      5      -1     19        0.7368        0.0288
      6       2     19        0.8947        0.0283

---

    Code
      round(sc$arc, 4)
    Output
      [1] -0.5000 -0.6667 -0.3333 -0.6667  0.3333  0.5000

