library(future)
library(sparklyr)
library(dplyr, warn.conflicts = FALSE)
library(ggplot2)

sc <- spark_connect(master = "local", spark_version = "2.3.0")

if(file.exists("source")) unlink("source", TRUE)
if(file.exists("source-out")) unlink("source-out", TRUE)

stream_generate_test(iterations = 1)
read_folder <- stream_read_csv(sc, "source") 

process_stream <- read_folder %>%
  stream_watermark() %>%
  group_by(timestamp) %>%
  summarise(
    max_x = max(x, na.rm = TRUE),
    min_x = min(x, na.rm = TRUE),
    count = n()
  )

invisible(future(stream_generate_test(interval = 0.2, iterations = 100)))

library(shiny)
ui <- function(){
  tableOutput("table")
}
server <- function(input, output, session){
  
  ps <- reactiveSpark(process_stream, session = session)
  
  output$table <- renderTable({
    ps() %>%
      mutate(timestamp = as.character(timestamp)) 
  })
}
runGadget(ui, server)
