library(sparklyr)
library(dplyr)
library(future)
sc <- spark_connect(master = "local")

if(file.exists("source")) unlink("source", TRUE)
if(file.exists("source-out")) unlink("source-out", TRUE)

stream_generate_test(iterations = 1)
read_folder <- stream_read_csv(sc, "source") 
write_output <- stream_write_csv(read_folder, "source-out")
invisible(future(stream_generate_test(interval = 0.5)))

stream_view(write_output)
stream_stop(write_output)

if(file.exists("source")) unlink("source", TRUE)

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

write_output <- stream_write_memory(process_stream, name = "stream")

invisible(future(stream_generate_test()))

stream_stop(write_output)
