library(sparklyr)
library(dplyr, warn.conflicts = FALSE)

sc <- spark_connect(master = "local", spark_version = "2.3.0")

if(file.exists("source")) unlink("source", TRUE)
if(file.exists("source-out")) unlink("source-out", TRUE)

df <- data.frame(x = rep(1:1000), y = rep(2:1001))

stream_generate_test(df = df, iteration = 1)

model_sample <- spark_read_csv(sc, "sample", "source")

pipeline <- sc %>%
  ml_pipeline() %>%
  ft_r_formula(x ~ y) %>%
  ml_linear_regression()

fitted_pipeline <- ml_fit(pipeline, model_sample)

ml_stream <- stream_read_csv(
  sc = sc, 
  path = "source", 
  columns = c(x = "integer", y = "integer")
)  %>%
  ml_transform(fitted_pipeline, .)  %>%
  select(- features) %>%
  stream_write_csv("source-out")

stream_generate_test(df = df, interval = 0.5)

spark_read_csv(sc, "stream", "source-out", memory = FALSE) 
stream_stop(ml_stream)
spark_disconnect(sc)
