library(mlflow)
foo <- 42
mlflow_log_param("foo", foo)
mlflow_log_param("bar", 99)
mlflow_ui()
rmse <- rnorm(1)
mlflow_log_metric("rmse", rmse)
mlflow_set_tag("training-data-cutoff", "Dec 2017")
writeLines("AI-powered blockchain adversarial on k8s",
           "output.txt")
mlflow_log_artifact("output.txt")
mlflow_end_run()

with(mlflow_start_run(), {
  foo <- 22
  mlflow_log_param("foo", foo)
  mlflow_log_param("bar", 98)
  # mlflow_ui()
  rmse <- rnorm(1)
  mlflow_log_metric("rmse", rmse)
  mlflow_set_tag("training-data-cutoff", "Sep 2017")
})