#'
#' Topic modelling of participants' expectations from the course. Themes are
#' discovered from the corpus first, then each response is coded against the
#' discovered themes.
#'

expectation_themes_type <- function() {
  ellmer::type_object(
    corpus_summary = ellmer::type_string(
      "Two or three sentences on what this cohort collectively wants from the course."
    ),
    themes = ellmer::type_array(
      description = "The induced codebook of themes.",
      items = ellmer::type_object(
        code = ellmer::type_string(
          "Short lowercase identifier, two or three words, spaces not underscores."
        ),
        label = ellmer::type_string("Human-readable title in sentence case."),
        description = ellmer::type_string(
          "One or two sentences defining what is in and out of the theme."
        ),
        exemplars = ellmer::type_array(
          description = "One to three verbatim quotes typifying the theme.",
          items = ellmer::type_string("A verbatim quote from a response.")
        ),
        n_estimate = ellmer::type_number(
          "Estimated number of responses expressing this theme."
        )
      )
    )
  )
}

expectation_coding_type <- function(codes) {
  ellmer::type_object(
    themes = ellmer::type_array(
      description = "Every theme the response expresses.",
      items = ellmer::type_enum(
        "A theme code from the codebook.",
        values = codes
      )
    ),
    primary_theme = ellmer::type_enum(
      "The theme the response leads with or dwells on most.",
      values = codes
    ),
    orientation = ellmer::type_enum(
      "What kind of expectation this mainly is.",
      values = c(
        "conceptual", "technical", "applied", "organisational", "multiple"
      )
    ),
    specificity = ellmer::type_enum(
      "Whether the response names something concrete or is an unelaborated hope.",
      values = c("specific", "general")
    ),
    confidence = ellmer::type_enum(
      "How firmly the response supports the coding.",
      values = c("high", "medium", "low")
    ),
    reasoning = ellmer::type_string(
      "One sentence naming the words that drove the primary theme."
    )
  )
}

#' Stage 1: induce a codebook of themes from the whole corpus ----

discover_expectation_themes_2026 <- function(expectations,
                                             prompt = "prompts/topic_discovery_expectations.md",
                                             model = "claude-opus-4-8") {
  corpus <- paste0(seq_along(expectations), ". ", expectations, collapse = "\n\n")

  theme_finder <- ellmer::chat_anthropic(
    system_prompt = paste(readLines(prompt, warn = FALSE), collapse = "\n"),
    model = model,
    echo = "none"
  )

  discovered <- theme_finder$chat_structured(
    paste0("Here are the ", length(expectations), " responses:\n\n", corpus),
    type = expectation_themes_type()
  )

  list(
    corpus_summary = discovered$corpus_summary,
    themes = discovered$themes |>
      tibble::as_tibble() |>
      dplyr::mutate(code = tolower(trimws(code)))
  )
}

#' Stage 2: code each response against the discovered codebook ----

code_expectations_2026 <- function(expectations,
                                   themes,
                                   prompt = "prompts/topic_assignment_expectations.md",
                                   model = "claude-opus-4-8") {
  codebook <- paste0(
    "- `", themes$code, "` (", themes$label, ") — ", themes$description,
    collapse = "\n"
  )

  coder <- ellmer::chat_anthropic(
    system_prompt = paste0(
      paste(readLines(prompt, warn = FALSE), collapse = "\n"),
      "\n\n## Codebook\n\n", codebook
    ),
    model = model,
    echo = "none"
  )

  ellmer::parallel_chat_structured(
    chat = coder,
    prompts = as.list(expectations),
    type = expectation_coding_type(codes = themes$code)
  ) |>
    tibble::as_tibble()
}

#' Run both stages and return tidy output ----

process_expectations_2026 <- function(expectations,
                                      model = "claude-opus-4-8") {
  expectations <- trimws(expectations)
  valid <- !is.na(expectations) & nzchar(expectations)

  discovered <- discover_expectation_themes_2026(
    expectations = expectations[valid], model = model
  )

  coded <- code_expectations_2026(
    expectations = expectations[valid],
    themes = discovered$themes,
    model = model
  )

  ## One row per participant, themes collapsed to a string for CSV safety ----
  participants <- tibble::tibble(
    expectation = expectations,
    primary_theme = NA_character_,
    orientation = NA_character_,
    specificity = NA_character_,
    confidence = NA_character_,
    reasoning = NA_character_,
    themes = NA_character_
  )

  ## Enums arrive as factors; keep them as labels, not integer codes ----
  participants$primary_theme[valid] <- as.character(coded$primary_theme)
  participants$orientation[valid] <- as.character(coded$orientation)
  participants$specificity[valid] <- as.character(coded$specificity)
  participants$confidence[valid] <- as.character(coded$confidence)
  participants$reasoning[valid] <- coded$reasoning
  participants$themes[valid] <- vapply(
    coded$themes, paste, character(1), collapse = "; "
  )

  ## One logical column per theme, for counting and plotting ----
  indicators <- lapply(
    X = discovered$themes$code,
    FUN = function(code) {
      out <- rep(NA, nrow(participants))
      out[valid] <- vapply(coded$themes, function(x) code %in% x, logical(1))
      out
    }
  ) |>
    stats::setNames(nm = make.names(discovered$themes$code)) |>
    tibble::as_tibble()

  ## One row per participant-theme pair, for tallying themes ----
  long <- tibble::tibble(
    participant = rep(which(valid), lengths(coded$themes)),
    theme = unlist(coded$themes)
  ) |>
    dplyr::left_join(
      dplyr::select(discovered$themes, code, label),
      by = c("theme" = "code")
    )

  list(
    corpus_summary = discovered$corpus_summary,
    themes = discovered$themes,
    participants = dplyr::bind_cols(participants, indicators),
    long = long
  )
}
