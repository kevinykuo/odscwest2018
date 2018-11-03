mlflow_run(
  "train.R",
  "https://github.com/rstudio/mlflow-example",
  param_list = list(alpha = 0.5, lambda = 0.1)
)
