library(mleap)
mleap_model <- mleap_load_bundle("saved_models/mleap-bundle.zip")

#* @post /predict
score_mleap <- function(
  origin, dest, dep_delay
) {
  pred_data <- data.frame(
    origin = origin, dest = dest, dep_delay = dep_delay,
    stringsAsFactors = FALSE
  )
  
  mleap_transform(mleap_model, pred_data)$prediction
}
