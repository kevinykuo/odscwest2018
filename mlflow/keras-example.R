library(mlflow)
library(keras)

model <- keras_model_sequential() %>%
  layer_dense(units = 8, activation = "relu", input_shape = dim(iris)[2] - 1) %>%
  layer_dense(units = 3, activation = "softmax")
model %>% compile(
  loss = "categorical_crossentropy",
  optimizer = optimizer_rmsprop(),
  metrics = c("accuracy")
)
train_x <- as.matrix(iris[, 1:4])
train_y <- to_categorical(as.numeric(iris[, 5]) - 1, 3)
model %>% fit(train_x, train_y, epochs = 5)
model %>% mlflow_save_model("model")

# restart R session

library(mlflow)
model_reloaded <- mlflow_load_model("model")

train_x <- as.matrix(iris[, 1:4])
predict(model_reloaded, train_x)

mlflow_rfunc_serve("model")
