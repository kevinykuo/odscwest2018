library(dplyr)
data <- nycflights13::flights %>%
  filter(!is.na(arr_delay)) %>%
  mutate(dep_delay = ifelse(is.na(dep_delay), 0, dep_delay))
glimpse(data)

names(data)

vars <- c("carrier", "dep_delay", "distance", "arr_delay")

library(rsample)

split <- initial_split(data)
train <- training(split)

test <- testing(split)


train %>%
  select(vars)
glimpse(train)
library(recipes)
rec <- recipe(train, vars = vars) %>%
  step_string2factor(carrier) %>%
  step_integer(carrier, zero_based = TRUE) %>%
  step_center(dep_delay, distance, arr_delay) %>%
  step_scale(dep_delay, distance, arr_delay) %>%
  prep()

baked_train <- bake(rec, train)
baked_test <- bake(rec, test)

library(keras)

carrier_input <- layer_input(1, name = "carrier")
distance_input <- layer_input(1, name = "distance")
dep_delay_input <- layer_input(1, name = "dep_delay")

carrier_embedding <- carrier_input %>%
  layer_embedding(16, 15, name = "carrier_embedding") %>%
  layer_flatten()

output <- layer_concatenate(
  list(carrier_embedding, distance_input, dep_delay_input)
) %>%
  layer_dense(128, activation = "relu") %>%
  layer_dropout(0.2) %>%
  layer_dense(64, activation = "relu") %>%
  layer_dense(1)

model1 <- keras_model(
  list(carrier_input, distance_input, dep_delay_input),
  list(output)
)

model1 %>%
  compile(optimizer = "adam", 
          loss = "mse",
          metrics = "mse"
  )

model1 %>%
  fit(
    x = list(
      dep_delay = baked_train$dep_delay,
      carrier = baked_train$carrier,
      distance = baked_train$distance
    ),
    y = baked_train$arr_delay,
    batch_size = 512,
    epochs = 5,
    validation_split = 0.2,
    callbacks = callback_tensorboard("log/run1")
  )

tensorboard("log/run1")

predictions <- predict(model1, list(
  dep_delay = baked_test$dep_delay,
  carrier = baked_test$carrier,
  distance = baked_test$distance
))
str(predictions)

# $sds
# dep_delay  distance arr_delay 
# 40.22813 735.47803  44.78368 
# 
# means
# dep_delay    distance   arr_delay 
# 12.589662 1047.274046    6.964429 

descale <- function(x) (x * 44.78368) + 6.964429
df <- data.frame(pred = descale(predictions))
glimpse(df)

library(ggplot2)
cbind(test, df) %>%
  ggplot(aes(x = arr_delay, y = pred)) +
  geom_point()
