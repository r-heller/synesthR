# STEP B: tokenize + sentiment + deep NRC emotion. Disk in, .rds out.
# No raw literary text is ever printed; only counts and score frames.
suppressMessages({
  library(gutenbergr); library(tokenizers); library(tibble)
  pkgload::load_all(".", quiet = TRUE)
})

strip_markers <- function(txt) {
  s <- grep("START OF (THE|THIS) PROJECT GUTENBERG", txt)
  e <- grep("END OF (THE|THIS) PROJECT GUTENBERG", txt)
  if (length(s) && length(e)) txt <- txt[(s[1] + 1):(e[1] - 1)]
  txt
}
to_sentences <- function(lines) {
  lines <- lines[nzchar(trimws(lines))]
  s <- tokenizers::tokenize_sentences(paste(lines, collapse = " "))[[1]]
  s <- trimws(s)
  s[nzchar(s) & nchar(s) > 3]
}
syuzhet_lang <- c(en = "english", de = "german", fr = "french")

# --- load three corpora from disk (no printing) ---
sh <- gutenbergr::gutenberg_strip(readRDS("data-raw/shakespeare.rds"))$text
sh <- sh[!grepl("^[[:space:]]*[0-9IVXLCDM]+[.]?[[:space:]]*$", sh)]  # drop sonnet-number headers
ba <- gutenbergr::gutenberg_strip(readRDS("data-raw/balzac.rds"))$text
go <- strip_markers(readLines("data-raw/goethe.txt", warn = FALSE, encoding = "UTF-8"))

sents <- list(
  shakespeare = list(lang = "en", s = to_sentences(sh), skip = 20),
  goethe      = list(lang = "de", s = to_sentences(go), skip = 220),  # past Zueignung/Prologe
  balzac      = list(lang = "fr", s = to_sentences(ba), skip = 90)
)
N <- 120L
emos <- c("anger","anticipation","disgust","fear","joy","sadness","surprise","trust")

build <- function(rec, author) {
  s <- rec$s
  i0 <- rec$skip + 1L
  i1 <- min(rec$skip + N, length(s))
  win <- s[i0:i1]
  tb <- tibble(sentence_id = seq_along(win), sentence = win, lang = rec$lang)
  attr(tb, "lang") <- rec$lang
  score <- syn_score(tb)
  saveRDS(score, sprintf("data-raw/score_%s.rds", author))
  f <- score$features
  emo <- syuzhet::get_nrc_sentiment(win, language = unname(syuzhet_lang[rec$lang]))
  out <- tibble(
    author = author, lang = rec$lang, sentence_id = f$sentence_id,
    valence = f$valence, length = f$length,
    lex_diversity = f$lex_diversity, punct_density = f$punct_density,
    arc = score$arc
  )
  cbind(out, emo[, emos])
}

all <- do.call(rbind, Map(build, sents, names(sents)))
saveRDS(all, "data-raw/features_all.rds")
saveRDS(all[, c(emos, "author")], "data-raw/emotions_long.rds")

# Aggregates only (scores, never text) ------------------------------------
agg <- aggregate(cbind(valence, lex_diversity, anger, joy, fear, sadness,
                       trust, anticipation) ~ author, data = all, FUN = mean)
cat("=== STEP B SUMMARY (scores only) ===\n")
cat("rows per author:\n"); print(table(all$author))
cat("\nfeature columns:", ncol(all), "\n")
cat(paste(names(all), collapse = ", "), "\n\n")
cat("mean valence + key emotions per author:\n")
print(format(agg, digits = 3))
cat("\nSTEP B DONE\n")
