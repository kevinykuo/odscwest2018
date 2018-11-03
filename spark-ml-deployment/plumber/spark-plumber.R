library(sparklyr)
sc <- spark_connect(master = "local", version = "2.3.0")
spark_model <- ml_load(sc, "saved_models/spark-pipeline")

#* @post /predict
score_spark <- function(
  origin, dest, dep_delay
) {
  pred_data <- data.frame(
    origin = origin, dest = dest, dep_delay = dep_delay,
    stringsAsFactors = FALSE
  )
  pred_data_tbl <- sdf_copy_to(sc, pred_data, overwrite = TRUE)
  
  ml_transform(spark_model, pred_data_tbl) %>%
    dplyr::pull(prediction)
}
