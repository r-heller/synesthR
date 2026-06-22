# synesthR demo app. No library() calls: everything is namespaced explicitly
# (synesthR::, shiny::) so the app is self-contained and check-clean.

.syn_audio_dir <- file.path(tempdir(), "synesthR_app_audio")
dir.create(.syn_audio_dir, showWarnings = FALSE, recursive = TRUE)
shiny::addResourcePath("syn_audio", .syn_audio_dir)

ui <- shiny::fluidPage(
  theme = NULL,
  shiny::tags$head(shiny::includeCSS(system.file("shiny", "synesthR", "www",
                                                  "custom.css", package = "synesthR"))),
  shiny::titlePanel("synesthR"),
  shiny::sidebarLayout(
    shiny::sidebarPanel(
      shiny::textAreaInput(
        "text", "Text",
        value = synesthR::syn_example_text("en"),
        rows = 8, placeholder = "Paste literary text (de / en / fr)..."
      ),
      shiny::selectInput("lang", "Language",
                         choices = c("English" = "en", "German" = "de", "French" = "fr"),
                         selected = "en"),
      shiny::numericInput("seed", "Seed", value = 1, min = 1, step = 1),
      shiny::actionButton("go", "Synthesize", class = "btn-primary"),
      shiny::tags$hr(),
      shiny::downloadButton("dl_img", "Download image"),
      shiny::downloadButton("dl_wav", "Download audio")
    ),
    shiny::mainPanel(
      shiny::plotOutput("image", height = "420px"),
      shiny::uiOutput("palette"),
      shiny::uiOutput("audio"),
      shiny::tags$hr(),
      shiny::tags$h4("Interpretation (optional)"),
      shiny::uiOutput("llm")
    )
  )
)

server <- function(input, output, session) {
  score <- shiny::eventReactive(input$go, {
    shiny::req(input$text)
    txt <- synesthR::syn_read_text(input$text, lang = input$lang)
    synesthR::syn_score(txt, seed = as.integer(input$seed))
  }, ignoreNULL = FALSE)

  output$image <- shiny::renderPlot({
    shiny::req(score())
    synesthR::syn_paint(score())
  })

  output$palette <- shiny::renderUI({
    shiny::req(score())
    pal <- synesthR::syn_palette(score())
    swatches <- lapply(pal$colors, function(col) {
      shiny::tags$span(style = sprintf(
        "display:inline-block;width:48px;height:48px;background:%s;border-radius:6px;margin:2px;",
        col))
    })
    shiny::tagList(shiny::tags$div(swatches),
                   shiny::tags$small(sprintf("palette: %s", pal$mode)))
  })

  wav_path <- shiny::reactive({
    shiny::req(score())
    f <- file.path(.syn_audio_dir, paste0("synesthR_", session$token, ".wav"))
    synesthR::syn_write_wav(score(), f, overwrite = TRUE)
    f
  })

  output$audio <- shiny::renderUI({
    shiny::req(wav_path())
    src <- file.path("syn_audio", basename(wav_path()))
    shiny::tags$audio(src = src, type = "audio/wav", controls = NA,
                      style = "width:100%;margin-top:8px;")
  })

  output$llm <- shiny::renderUI({
    shiny::req(score())
    reachable <- requireNamespace("ellmer", quietly = TRUE) &&
      tryCatch({ ellmer::chat_ollama(model = "mistral-small"); TRUE },
               error = function(e) FALSE)
    if (!reachable) {
      shiny::tags$em(paste(
        "Local LLM interpretation is unavailable.",
        "Install 'ellmer' and run a local Ollama server to enable it."
      ))
    } else {
      shiny::tagList(
        shiny::actionButton("interpret", "Interpret"),
        shiny::verbatimTextOutput("interpretation")
      )
    }
  })

  output$interpretation <- shiny::renderText({
    shiny::req(input$interpret)
    tryCatch(synesthR::syn_interpret(score()),
             error = function(e) conditionMessage(e))
  })

  output$dl_img <- shiny::downloadHandler(
    filename = function() "synesthR.png",
    content = function(file) {
      ggplot2::ggsave(file, synesthR::syn_paint(score()),
                      width = 6, height = 6, dpi = 150)
    }
  )
  output$dl_wav <- shiny::downloadHandler(
    filename = function() "synesthR.wav",
    content = function(file) synesthR::syn_write_wav(score(), file, overwrite = TRUE)
  )
}

shiny::shinyApp(ui, server)
