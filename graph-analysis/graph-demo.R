library(graphframes)
library(sparklyr)
library(dplyr)
library(visNetwork)

sc <- spark_connect(master = "local", version = "2.3.0")

# Grab list of CRAN packages and their dependencies
available_packages <- available.packages(
  contrib.url("https://cloud.r-project.org/")
) %>%
  `[`(, c("Package", "Depends", "Imports")) %>%
  as_tibble() %>%
  transmute(
    package = Package,
    dependencies = paste(Depends, Imports, sep = ",") %>%
      gsub("\\n|\\s+", "", .)
  )

# Copy data to Spark
packages_tbl <- sdf_copy_to(sc, available_packages, overwrite = TRUE)

# Create a tidy table of dependencies, which define the edges of our graph
edges_tbl <- packages_tbl %>%
  mutate(
    dependencies = dependencies %>%
      regexp_replace("\\\\(([^)]+)\\\\)", "")
  ) %>%
  ft_regex_tokenizer(
    "dependencies", "dependencies_vector",
    pattern = "(\\s+)?,(\\s+)?", to_lower_case = FALSE
  ) %>%
  transmute(
    src = package,
    dst = explode(dependencies_vector)
  ) %>%
  filter(!dst %in% c("R", "NA"))

g <- gf_graphframe(edges = edges_tbl)
g
spark_set_checkpoint_dir(sc, tempdir())
cc <- gf_connected_components(g)

component_count <- cc %>%
  group_by(component) %>%
  count() %>%
  arrange(desc(n))

small_components <- component_count %>%
  filter(n < 5) %>%
  left_join(cc, by = "component") %>%
  ungroup() %>%
  pull(id)

edges <- edges_tbl %>%
  filter(
    src %in% !!small_components |
      dst %in% !!small_components
  ) %>%
  rename(from = src, to = dst) %>%
  collect()

vertices <- g %>%
  gf_vertices() %>%
  filter(id %in% !!small_components) %>%
  mutate(title = id,
         label = id) %>%
  collect()

visNetwork(vertices, edges, width = "100%") %>%
  visEdges(arrows = "to")

pagerank_result <- gf_pagerank(g, max_iter = 100)
pr <- pagerank_result %>%
  gf_vertices() %>%
  arrange(desc(pagerank)) %>%
  head(100) %>%
  collect()
