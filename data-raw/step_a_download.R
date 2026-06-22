# STEP A: fetch the three classic corpora to disk. Texts never enter the
# console — only counts and file sizes are reported.
suppressMessages(library(gutenbergr))
mirror <- "https://gutenberg.pglaf.org"

shakespeare <- gutenberg_download(1041,  mirror = mirror)   # EN, The Sonnets
balzac      <- gutenberg_download(11049, mirror = mirror)   # FR, Eugénie Grandet
saveRDS(shakespeare, "data-raw/shakespeare.rds")
saveRDS(balzac,      "data-raw/balzac.rds")

options(timeout = 180)
download.file("https://www.gutenberg.org/cache/epub/2229/pg2229.txt",
              "data-raw/goethe.txt", mode = "wb", quiet = TRUE)  # DE, Faust I

cat(sprintf("shakespeare.rds lines=%d bytes=%d\n", nrow(shakespeare), file.size("data-raw/shakespeare.rds")))
cat(sprintf("balzac.rds      lines=%d bytes=%d\n", nrow(balzac),      file.size("data-raw/balzac.rds")))
cat(sprintf("goethe.txt      bytes=%d\n", file.size("data-raw/goethe.txt")))
