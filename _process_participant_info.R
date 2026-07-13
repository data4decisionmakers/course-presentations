# Process participants responses -----------------------------------------------


## Load libraries and custom functions ----
suppressPackageStartupMessages(source("packages.R"))
for (f in list.files(here::here("R"), full.names = TRUE)) source (f)



## Process participant responses 2026 ----

file_path <- "data/d4dm_participant_information_2026.csv"

participant_info_2026 <- read.csv(file_path) |>
  process_participant_responses_2026()


## Classify roles 2026 ----

roles_classification_2026 <- process_roles_2026(participant_info_2026$role)

## output the results to a CSV file ----
write.csv(
  x = roles_classification_2026,
  file = "data/roles_classification_2026.csv",
  row.names = FALSE
)


## Classify data roles 2026 ----

themes_2026 <- discover_data_role_themes_2026(participant_info_2026$data_role)

write.csv(
  x = themes_2026$themes |>
    dplyr::mutate(
      exemplars = lapply(
        X = exemplars, FUN = paste, collapse = "; "
      ) |>
        unlist()
    ),
  file = "data/data_role_themes_2026.csv",
  row.names = FALSE
)

## Every run after that: code against the saved codebook ----
data_roles_2026 <- code_data_roles_2026(
  data_roles = participant_info_2026$data_role,
  themes = read.csv("data/data_role_themes_2026.csv")
) |>
  dplyr::mutate(
    themes = lapply(
      X = themes, FUN = paste, collapse = "; "
    ) |>
      unlist()
  )

write.csv(
  x = data_roles_2026,
  file = "data/data_roles_2026.csv",
  row.names = FALSE
)


## Classify expectations 2026 ----

expectations_themes_2026 <- discover_expectation_themes_2026(
  participant_info_2026$expectations
)

write.csv(
  x = expectations_themes_2026$themes |>
    dplyr::mutate(
      exemplars = lapply(
        X = exemplars, FUN = paste, collapse = "; "
      ) |>
        unlist()
    ),
  file = "data/expectations_themes_2026.csv",
  row.names = FALSE
)

## Every run after that: code against the saved codebook ----
expectations_2026 <- code_expectations_2026(
  expectations = participant_info_2026$expectations,
  themes = read.csv("data/expectations_themes_2026.csv")
) |>
  dplyr::mutate(
    themes = lapply(
      X = themes, FUN = paste, collapse = "; "
    ) |>
      unlist()
  )

write.csv(
  x = expectations_2026,
  file = "data/expectations_2026.csv",
  row.names = FALSE
)
