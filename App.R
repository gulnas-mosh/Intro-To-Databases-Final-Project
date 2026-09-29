library(shiny)
library(RMySQL)
library(ggplot2)
library(scales)

# ---------------------------------------------------------------------------
# Connection - identical to createDB/loadDB/testDBLoading, confirmed working
# ---------------------------------------------------------------------------
db_host_aiven <- Sys.getenv("DB_HOST")
db_port_aiven <- as.integer(Sys.getenv("DB_PORT"))
db_name_aiven <- Sys.getenv("DB_NAME")
db_user_aiven <- Sys.getenv("DB_USER")
db_pwd_aiven  <- Sys.getenv("DB_PASSWORD")

db_cert <- "-----BEGIN CERTIFICATE-----
MIIERDCCAqygAwIBAgIUW1UKnJrctcFTRgPkgID5dqABwAwwDQYJKoZIhvcNAQEM
BQAwOjE4MDYGA1UEAwwvMzA0NjZjNzYtMzBlYi00N2Q1LWJmN2MtOTI1MDJjZTA3
NzA3IFByb2plY3QgQ0EwHhcNMjYwODAzMDUxNzQxWhcNMzYwNzMxMDUxNzQxWjA6
MTgwNgYDVQQDDC8zMDQ2NmM3Ni0zMGViLTQ3ZDUtYmY3Yy05MjUwMmNlMDc3MDcg
UHJvamVjdCBDQTCCAaIwDQYJKoZIhvcNAQEBBQADggGPADCCAYoCggGBAKktoIqT
ppOSWuhXKvkZTlb+lei94CS943eJbvo4PZRGyANx0nlckvTmfRkj6MfCmdg1Niml
n1X23X29BgXYAuAG2m6mt7+6iQpigrCZU3oRcyDmXi1eYjWwf/D3N9TZ7kVSiNc1
VNkGkSFBFBc/+DDxEq7MIjAa9O0j8Z4ad1f6YwkvV2AAkX+e9M53C7b0FnyqL9bp
SuB76gf8xF6puZANUBU2qie9oTfn4/z4Tt7HgSf8L0A/VTRkuiPc2dvBxcDn/72g
qZr10v7JxQ3e8yEnc8SaXUPlhJQYJlvcxdKMDse6sLvM8FK8CbgufXdvX8mVCX+F
/sZltY+WNd8r4+zFwTfGBsj81Iu5yalG+Xk0ucax0lw3vuTJOt35zt8My9WDKMFJ
I3MjeipphZj9pMZN0nBo1y8OmjLYzLLp6RoByKMt/v9Q+vzNVaH443OeVqYq4X1b
UnRW5gdkLsROm2DlsX7zNMTMa0BliCSsQlEOQk9WP7aPrs7SlxFcWXR1oQIDAQAB
o0IwQDAdBgNVHQ4EFgQUWZK4aXKMchLeJkAW6OEDxMbr3NQwEgYDVR0TAQH/BAgw
BgEB/wIBADALBgNVHQ8EBAMCAQYwDQYJKoZIhvcNAQEMBQADggGBADjxFcC8ld/p
cwXbx1WQnXTEHma9gYfNYYeetRD8kwvB6UtQqsqig+vq8hevvyBbq2cHn0TXSCxN
KMDt32T5nVkeAd5mB3tOM1VbtC1+bIUTqIm7THAlPyzN6w7xO8TzLKFRRjVbfhIB
B6AJ80FXb+cF1L9szy/dDKUy5mWBdwXbAQ6hObRUSCERVkyy2Wdu1CfwE6G7d/Mc
S8mEZ0TLoyXoW3B8LVWzdWzssahpe1+hywVIrwMmcLeqcSMeSi48Xo1oAXOU18t2
89hONKBHw9o60C0SBEMnIyYvtKYYcEDFr3vnS3vIIb8p39mlcmx01iVF0qM4zc8d
8GUrQKQIjRK6DA6A03wgCaweWHIhkZnLHBvCvzzniuP3PJ1iT3YsAGqz8JkgTOUb
HV24kx+Kqyavwhx/mv4J8bjRVJFIAuxf+fqXBft1FPTFm7Z9pwedEdAjY/4Nh1lC
o+jpepWr3zKFjpVsYqdqI8BgTGiZkYZSaijCcJ0QF30RR4k6bKbL4Q==
-----END CERTIFICATE-----"

get_connection <- function() {
  dbConnect(RMySQL::MySQL(),
            user = db_user_aiven, password = db_pwd_aiven,
            dbname = db_name_aiven, host = db_host_aiven, port = db_port_aiven,
            sslmode = "require", sslcert = db_cert)
}

# ---------------------------------------------------------------------------
# Palette (same as the earlier React version)
# ---------------------------------------------------------------------------
BG <- "#24262B"; PANEL <- "#2E3138"; PANEL_LINE <- "#3B3F47"
GOLD <- "#C9973F"; INK <- "#EDE3CE"; INK_DIM <- "#B9AF95"
SAGE <- "#7C8B6C"; RUST <- "#A6573E"; BLUE <- "#8C9BB5"

dark_theme <- function() {
  theme_minimal(base_family = "IBM Plex Sans") +
    theme(
      plot.background  = element_rect(fill = PANEL, color = NA),
      panel.background = element_rect(fill = PANEL, color = NA),
      panel.grid.major  = element_line(color = PANEL_LINE, linewidth = 0.3),
      panel.grid.minor  = element_blank(),
      axis.text  = element_text(color = INK_DIM, size = 9),
      axis.title = element_blank(),
      legend.position = "none",
      plot.margin = margin(4, 8, 0, 0)
    )
}

# ---------------------------------------------------------------------------
# UI
# ---------------------------------------------------------------------------
ui <- fluidPage(
  tags$head(
    tags$style(HTML(sprintf("
      @import url('https://fonts.googleapis.com/css2?family=Fraunces:wght@600;700&family=IBM+Plex+Sans:wght@400;500;600&family=IBM+Plex+Mono:wght@500;600&display=swap');
      body { background-color: %s; color: %s; font-family: 'IBM Plex Sans', sans-serif; }
      .title-block h1 { font-family: 'Fraunces', serif; color: %s; font-size: 26px; margin-bottom: 0; }
      .subtitle { color: %s; font-size: 12.5px; }
      .kpi-box { background: %s; border: 1px solid %s; border-left: 3px solid %s;
                 border-radius: 6px; padding: 10px 14px; text-align: left; }
      .kpi-value { font-family: 'IBM Plex Mono', monospace; font-size: 22px; font-weight: 600; color: %s; }
      .kpi-label { font-size: 10px; color: %s; text-transform: uppercase; letter-spacing: .06em; }
      .panel-box { background: %s; border: 1px solid %s; border-radius: 6px; padding: 10px 14px; }
      .panel-title { color: %s; font-size: 11px; font-weight: 600; letter-spacing: .08em;
                     text-transform: uppercase; margin-bottom: 6px; }
      .nav-tabs { border-bottom: 1px solid %s; }
      .nav-tabs > li > a { color: %s; background: transparent; border: none; }
      .nav-tabs > li.active > a { color: %s !important; background: %s !important; border: none !important; }
      .form-control, select.form-control { background: #1B1D21; color: %s; border: 1px solid %s; }
      .btn-gold { background: %s; color: #1B1D21; font-weight: 600; border: none; }
      .wax-seal { width: 56px; height: 56px; border-radius: 50%%; border: 2px solid %s;
                  display:flex; align-items:center; justify-content:center; transform: rotate(-6deg);
                  background: radial-gradient(circle at 35%% 30%%, #3a3428, #241f18);
                  font-family:'Fraunces', serif; font-weight:700; color:%s; float:right; }
      hr { border-color: %s; }
      table.shiny-table, table.shiny-table td, table.shiny-table th,
      .table, .table td, .table th {
        background-color: %s !important;
        color: %s !important;
        border-color: %s !important;
      }
      .table > tbody > tr > td, .table > thead > tr > th { border-top: 1px solid %s; }
      .table > tbody > tr:nth-of-type(odd), .table > tbody > tr:nth-of-type(even) {
        background-color: %s !important;
      }
    ", BG, INK, INK, INK_DIM, PANEL, PANEL_LINE, GOLD, INK, INK_DIM,
                            PANEL, PANEL_LINE, GOLD, PANEL_LINE, INK_DIM, BG, GOLD, INK, PANEL_LINE,
                            GOLD, GOLD, INK, PANEL_LINE,
                            PANEL, INK, PANEL_LINE, PANEL_LINE, PANEL)))
  ),
  
  fluidRow(
    column(9, div(class = "title-block",
                  h1("Maison Beaumont Affinage"),
                  div(class = "subtitle", "Cave Ledger — Production & Aging Overview (live database)")
    )),
    column(3, div(class = "wax-seal", "MBA"))
  ),
  br(),
  
  tabsetPanel(
    tabPanel("Overview",
             br(),
             fluidRow(
               column(2, div(class = "kpi-box", div(class = "kpi-value", textOutput("kpi_batches", inline = TRUE)), div(class = "kpi-label", "Total Batches"))),
               column(2, div(class = "kpi-box", div(class = "kpi-value", textOutput("kpi_wheels", inline = TRUE)), div(class = "kpi-label", "Wheels Produced"))),
               column(2, div(class = "kpi-box", div(class = "kpi-value", textOutput("kpi_types", inline = TRUE)), div(class = "kpi-label", "Cheese Types"))),
               column(2, div(class = "kpi-box", div(class = "kpi-value", textOutput("kpi_countries", inline = TRUE)), div(class = "kpi-label", "Origin Countries"))),
               column(2, div(class = "kpi-box", div(class = "kpi-value", textOutput("kpi_caves", inline = TRUE)), div(class = "kpi-label", "Aging Caves")))
             ),
             br(),
             fluidRow(
               column(7, div(class = "panel-box", div(class = "panel-title", "Batches Started per Month"),
                             plotOutput("plot_trend", height = "230px"))),
               column(5, div(class = "panel-box", div(class = "panel-title", "Batches by Origin Country"),
                             plotOutput("plot_country", height = "230px")))
             ),
             br(),
             fluidRow(
               column(5, div(class = "panel-box", div(class = "panel-title", "Most-Produced Cheese Types"),
                             plotOutput("plot_types", height = "200px"))),
               column(4, div(class = "panel-box", div(class = "panel-title", "Quality Grade Distribution"),
                             plotOutput("plot_grade", height = "200px"))),
               column(3, div(class = "panel-box", div(class = "panel-title", "Batches by Milk Animal"),
                             plotOutput("plot_animal", height = "200px")))
             )
    ),
    
    tabPanel("New Batch",
             br(),
             fluidRow(
               column(5,
                      div(class = "panel-box",
                          div(class = "panel-title", "Record a New Production Batch"),
                          p(style = paste0("color:", INK_DIM, "; font-size:12px;"),
                            "Calls storeProduct(batch_id, production_date, batch_size_liters, ",
                            "wheels_produced, coagulant_type, cheese_type_id, supplier_id) - ",
                            "the stored procedure defined in configBusinessLogic.PractI.MoshkovichG.R."),
                          textInput("batch_id", "Batch ID", placeholder = "e.g. BT9002"),
                          dateInput("prod_date", "Production Date", value = Sys.Date()),
                          numericInput("batch_size", "Batch Size (liters)", value = 480, min = 1),
                          numericInput("wheels", "Wheels Produced", value = 60, min = 1),
                          selectInput("coagulant", "Coagulant Type",
                                      choices = c("Animal Rennet", "Microbial Rennet", "Vegetable Rennet")),
                          uiOutput("cheese_type_select"),
                          uiOutput("supplier_select"),
                          actionButton("submit_batch", "Add Batch", class = "btn-gold"),
                          br(), br(),
                          textOutput("submit_status")
                      )
               ),
               column(7,
                      div(class = "panel-box",
                          div(class = "panel-title", "Recent Batches (live from database)"),
                          tableOutput("recent_batches")
                      )
               )
             )
    )
  )
)

# ---------------------------------------------------------------------------
# Server
# ---------------------------------------------------------------------------
server <- function(input, output, session) {
  
  data <- reactiveValues()
  
  refresh_data <- function() {
    con <- get_connection()
    
    data$kpis <- dbGetQuery(con, "
      SELECT (SELECT COUNT(*) FROM batches) AS batches,
             (SELECT SUM(wheels_produced) FROM batches) AS wheels,
             (SELECT COUNT(*) FROM cheese_types) AS types,
             (SELECT COUNT(DISTINCT farm_country) FROM suppliers) AS countries,
             (SELECT COUNT(*) FROM caves) AS caves")
    
    data$trend <- dbGetQuery(con, "
      SELECT DATE_FORMAT(production_date, '%Y-%m') AS month, COUNT(*) AS n
        FROM batches GROUP BY month ORDER BY month")
    
    data$country <- dbGetQuery(con, "
      SELECT s.farm_country AS country, COUNT(*) AS n
        FROM batches b JOIN suppliers s ON b.supplier_id = s.supplier_id
       GROUP BY s.farm_country ORDER BY n DESC")
    
    data$types <- dbGetQuery(con, "
      SELECT c.cheese_type_name AS type, COUNT(*) AS n
        FROM batches b JOIN cheese_types c ON b.cheese_type_id = c.cheese_type_id
       GROUP BY c.cheese_type_name ORDER BY n DESC LIMIT 7")
    
    data$grade <- dbGetQuery(con, "
      SELECT quality_grade AS grade, COUNT(*) AS n
        FROM aging_records GROUP BY quality_grade")
    
    data$animal <- dbGetQuery(con, "
      SELECT c.milk_animal AS animal, COUNT(*) AS n
        FROM batches b JOIN cheese_types c ON b.cheese_type_id = c.cheese_type_id
       GROUP BY c.milk_animal")
    
    data$cheese_types_lookup <- dbGetQuery(con, "SELECT cheese_type_id, cheese_type_name FROM cheese_types ORDER BY cheese_type_id")
    data$suppliers_lookup    <- dbGetQuery(con, "SELECT supplier_id, farm_name FROM suppliers ORDER BY supplier_id")
    
    data$recent <- dbGetQuery(con, "
      SELECT batch_id, production_date, batch_size_liters, wheels_produced, coagulant_type
        FROM batches ORDER BY batch_id DESC LIMIT 8")
    
    dbDisconnect(con)
  }
  
  refresh_data()
  
  output$kpi_batches   <- renderText(format(data$kpis$batches, big.mark = ","))
  output$kpi_wheels    <- renderText(format(data$kpis$wheels, big.mark = ","))
  output$kpi_types     <- renderText(as.character(data$kpis$types))
  output$kpi_countries <- renderText(as.character(data$kpis$countries))
  output$kpi_caves     <- renderText(as.character(data$kpis$caves))
  
  output$plot_trend <- renderPlot({
    ggplot(data$trend, aes(x = month, y = n, group = 1)) +
      geom_line(color = GOLD, linewidth = 1) +
      geom_point(color = GOLD, size = 1.6) +
      scale_x_discrete(breaks = data$trend$month[seq(1, nrow(data$trend), by = 3)]) +
      dark_theme() + theme(axis.text.x = element_text(angle = 45, hjust = 1, size = 7.5))
  }, bg = "transparent")
  
  output$plot_country <- renderPlot({
    ggplot(data$country, aes(x = reorder(country, n), y = n)) +
      geom_col(fill = SAGE, width = 0.65) + coord_flip() +
      dark_theme() + theme(axis.text.y = element_text(size = 10.5, color = INK))
  }, bg = "transparent")
  
  output$plot_types <- renderPlot({
    ggplot(data$types, aes(x = reorder(type, n), y = n)) +
      geom_col(fill = GOLD, width = 0.6) + coord_flip() +
      dark_theme() + theme(axis.text.y = element_text(size = 9, color = INK))
  }, bg = "transparent")
  
  output$plot_grade <- renderPlot({
    ggplot(data$grade, aes(x = "", y = n, fill = grade)) +
      geom_col(width = 1, color = PANEL) + coord_polar(theta = "y") +
      scale_fill_manual(values = c(GOLD, SAGE, RUST, BLUE, "#6B5A45", INK_DIM, "#5A6350")) +
      dark_theme() + theme(axis.text = element_blank(), legend.position = "right",
                           legend.text = element_text(color = INK, size = 9), legend.title = element_blank())
  }, bg = "transparent")
  
  output$plot_animal <- renderPlot({
    ggplot(data$animal, aes(x = animal, y = n, fill = animal)) +
      geom_col(width = 0.6) +
      scale_fill_manual(values = c(Cow = RUST, Sheep = BLUE, Goat = SAGE)) +
      dark_theme() + theme(axis.text.x = element_text(size = 10, color = INK))
  }, bg = "transparent")
  
  output$cheese_type_select <- renderUI({
    opts <- setNames(data$cheese_types_lookup$cheese_type_id,
                     paste(data$cheese_types_lookup$cheese_type_id, "-", data$cheese_types_lookup$cheese_type_name))
    selectInput("cheese_type", "Cheese Type (existing)", choices = opts)
  })
  
  output$supplier_select <- renderUI({
    opts <- setNames(data$suppliers_lookup$supplier_id,
                     paste(data$suppliers_lookup$supplier_id, "-", data$suppliers_lookup$farm_name))
    selectInput("supplier", "Supplier (existing)", choices = opts)
  })
  
  output$recent_batches <- renderTable(data$recent, striped = FALSE, spacing = "s")
  
  observeEvent(input$submit_batch, {
    if (nchar(trimws(input$batch_id)) == 0) {
      output$submit_status <- renderText("Batch ID is required.")
      return()
    }
    
    con <- get_connection()
    result <- tryCatch({
      # Build the CALL text directly with paste0(), the same fix already
      # applied in configBusinessLogic.PractI.MoshkovichG.R - RMySQL's ?
      # placeholders were not being substituted and were sent to MySQL
      # as literal question marks, causing a syntax error.
      esc <- function(x) gsub("'", "''", x)
      call_sql <- paste0(
        "CALL storeProduct('", esc(input$batch_id), "', ",
        "'", as.character(input$prod_date), "', ",
        input$batch_size, ", ",
        input$wheels, ", ",
        "'", esc(input$coagulant), "', ",
        "'", esc(input$cheese_type), "', ",
        "'", esc(input$supplier), "')"
      )
      rs <- dbSendQuery(con, call_sql)
      fetch(rs, n = -1)
      while (dbMoreResults(con)) dbNextResult(con)
      TRUE
    }, error = function(e) { conditionMessage(e) })
    dbDisconnect(con)
    
    if (isTRUE(result)) {
      output$submit_status <- renderText(paste("Added batch", input$batch_id, "successfully."))
      updateTextInput(session, "batch_id", value = "")
      refresh_data()
    } else {
      output$submit_status <- renderText(paste("Failed:", result))
    }
  })
}

shinyApp(ui, server)