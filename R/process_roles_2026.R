#'
#' Process roles for 2026 participants
#'

role_classification_type <- function() {
  ellmer::type_object(
    seniority = ellmer::type_enum(
      "Seniority level implied by the role.",
      values = c(
        "executive", "senior management", "middle management",
        "senior specialist", "officer", "junior", "unknown"
      )
    ),
    function_type = ellmer::type_enum(
      "Whether the role is administrative/operational, technical, or both.",
      values = c("administrative", "technical", "both", "unclear")
    ),
    confidence = ellmer::type_enum(
      "How firmly the role text supports the classification.",
      values = c("high", "medium", "low")
    ),
    reasoning = ellmer::type_string(
      "One sentence naming the words in the role that drove the decision."
    )
  )
}

process_roles_2026 <- function(roles,
                               prompt = "prompts/classification_role.md",
                               model = "claude-opus-4-8") {
  ## Classify each distinct role once and map the results back ----
  distinct_roles <- unique(trimws(roles))
  distinct_roles <- distinct_roles[!is.na(distinct_roles) & nzchar(distinct_roles)]

  role_classifier <- ellmer::chat_anthropic(
    system_prompt = paste(readLines(prompt, warn = FALSE), collapse = "\n"),
    model = model,
    echo = "none"
  )

  classified <- ellmer::parallel_chat_structured(
    chat = role_classifier,
    prompts = as.list(distinct_roles),
    type = role_classification_type()
  ) |>
    tibble::as_tibble() |>
    dplyr::mutate(role = distinct_roles, .before = 1)

  tibble::tibble(role = trimws(roles)) |>
    dplyr::left_join(classified, by = "role") |>
    ## Blank and missing roles never reach the model, so label them here ----
    dplyr::mutate(
      seniority = dplyr::coalesce(seniority, "unknown"),
      function_type = dplyr::coalesce(function_type, "unclear"),
      confidence = dplyr::coalesce(confidence, "low"),
      reasoning = dplyr::coalesce(reasoning, "No role was provided.")
    ) |>
    dplyr::mutate(
      seniority = factor(
        seniority,
        levels = c(
          "executive", "senior_management", "middle_management",
          "senior_specialist", "officer", "junior", "unknown"
        )
      ),
      function_type = factor(
        function_type,
        levels = c("administrative", "technical", "both", "unclear")
      )
    )
}
