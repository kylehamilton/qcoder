#
# This is a Shiny web application. You can run the application by clicking
# the 'Run App' button above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#
if (interactive()) {
  library(shiny)
  library(dplyr)
  library(magrittr)
  library(shinyAce)
  library(rlang)
  library(stringr)
  # hard coded for now

  # Define UI for application
  ui <- fluidPage(

    mainPanel(
      textInput("text_doc_path", label = h4("Enter full path to your document data frame"),
                value = "" ),
      # test string
      # "/Users/elinwaring/Code/rcode/qcoder/data/qcoder_example_markedup.rds"
      actionButton("load_documents", "Load Documents"),
      textInput("code_path", label = h4("Enter full path to your code data frame"),
                value = ""),
           # test string /Users/elinwaring/Code/rcode/qcoder/data/example_codes.rds
      actionButton("load_codes", "Load Codes"),
        # End upper section
      # Start tabset
      tabsetPanel(
           # Tab title
           tabPanel("Add codes to text data",
            conditionalPanel(condition = "input.text_doc_path == TRUE",
             # Edit box and document selector
             # make sure these are unique
               uiOutput( "doc_list" ),
               uiOutput("saveButton"),
               uiOutput("mydocA"),
               verbatimTextOutput("this_doc" )
            )
       ), # close editor panel
       tabPanel("Codes",
                tableOutput('code_table')

      ), # close codes tab panel
      tabPanel("Add Code",
               actionButton("add_code", "Add")

      ), # close add code panel
      tabPanel("Coded data",
               tableOutput('coded')

      ) # close coded tab panel
    ) # close tab set
  ) # close main panel
  )
  }
  # Define server logic
  server <- function(input, output, session) {

    choices <- function(text_df){
      text_df <- readRDS(input$text_doc_path)
      options <- text_df["doc_path"]
      options <- c(" ", options)
      options
    }
    # This should observer the load_documents event
    #output$doc_list <-  observeEvent(input$load_documents,{renderUI({
    output$doc_list <-  renderUI({
      if (input$text_doc_path == ""){
        return()}
       selectInput('this_doc_path', 'Document', choices())
      })

    #})

    output$saveButton <- renderUI({
      if (input$text_doc_path == ""){
        return()}
      actionButton("submit", "Save changes")
    })

    # Functions related to rendering an individual text document in an editor and
    # verbatim
    # Consider making a backup each time you load this.
    doc <- reactive ({
      if (input$text_doc_path == "") {return()}
      if (length(input$this_doc_path) != 1) {return()}
      text_df <- readRDS(input$text_doc_path)
      this_doc <- text_df %>%
        filter(doc_path == as.character(input$this_doc_path)) %>%
        select(document_text)
       # Sanitize this
       return(as.character(this_doc[1, "document_text"]))
      })

    # Create the text editor
    output$mydocA <- renderUI({
      if (input$text_doc_path == "" ) {return()}
      aceEditor(
        "edited_doc",
        value = doc(),
        mode = "markdown",
        height = "500",
        cursorId = "cursor",
        hotkeys=list()

      )
    })

    output$this_doc <-{
          renderText(doc())
      }


    # Functions related to updating the text.
    do_update_document <- observeEvent(input$submit,{
      text_df <- readRDS(input$text_doc_path)
      row_num <- which(text_df[,"doc_path"] == input$this_doc_path)
      text_df[row_num, "document_text"] <- input$edited_doc
      # make sure this save happens
      saveRDS(text_df, file = input$text_doc_path)
      invisible(TRUE)
    })
    # Get the code data for display
    output$code_table <- renderTable({
      if (input$code_path == "") {return()}
      code_df <- readRDS(input$code_path)
      code_df
    })

    # Get the parsed values with codes.
    output$coded <- renderTable({
      if (input$text_doc_path == "" ) {return()}
      text_df <- readRDS(input$text_doc_path)
      qcoder::parse_qcodes(text_df)
    })

  }

# Run the application
shinyApp(ui = ui, server = server)

