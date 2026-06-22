# Round numeric columns of a data frame for stable snapshots across platforms.
round_df <- function(df, digits = 4) {
  num <- vapply(df, is.numeric, logical(1))
  df[num] <- lapply(df[num], round, digits = digits)
  df
}
