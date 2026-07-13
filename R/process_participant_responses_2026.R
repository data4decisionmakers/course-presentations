#'
#' Process participant responses 2026
#' 

process_participant_responses_2026 <- function(.data) {
  .data |>
    dplyr::select(7:11) |>
    stats::setNames(
      nm = c("agency", "role", "data_role", "expectations", "data_definition")
    ) |>
    tibble::as_tibble() |>
    dplyr::mutate(
      dplyr::across(
        .cols = dplyr::everything(),
        .fns = trimws
      )
    ) |>
    dplyr::mutate(
      agency = lapply(
        X = agency, FUN = stringdist::amatch,
        table = agency[c(1:2, 6, 8, 9, 14)], maxDist = 6
      ) |>
        unlist() |>
        (\(x) agency[c(1:2, 6, 8, 9, 14)][x])() |>
        (\(x) ifelse(x == "Presidents Office", "President's Office", x))(),
      role = stringr::str_replace(
        string = role, pattern = "Seniir", replacement = "Senior"
      )
    )
}
