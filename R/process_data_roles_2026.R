#'
#' Topic modelling of participants' descriptions of how their role relates to
#' data. Themes are discovered from the corpus first, then each response is
#' coded against the discovered themes.
#'

data_role_themes_type <- function() {
  ellmer::type_object(
    corpus_summary = ellmer::type_string(
      "Two or three sentences on the cohort's overall relationship to data."
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

data_role_coding_type <- function(codes) {
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
    engagement = ellmer::type_enum(
      "How hands-on the person is with data.",
      values = c("producer", "handler", "analyst", "consumer", "multiple")
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

discover_data_role_themes_2026 <- function(data_roles,
                                           prompt = "prompts/topic_discovery_data_role.md",
                                           model = "claude-opus-4-8") {
  corpus <- paste0(seq_along(data_roles), ". ", data_roles, collapse = "\n\n")

  theme_finder <- ellmer::chat_anthropic(
    system_prompt = paste(readLines(prompt, warn = FALSE), collapse = "\n"),
    model = model,
    echo = "none"
  )

  discovered <- theme_finder$chat_structured(
    paste0("Here are the ", length(data_roles), " responses:\n\n", corpus),
    type = data_role_themes_type()
  )

  list(
    corpus_summary = discovered$corpus_summary,
    themes = discovered$themes |>
      tibble::as_tibble() |>
      dplyr::mutate(code = tolower(trimws(code)))
  )
}

#' Stage 2: code each response against the discovered codebook ----

code_data_roles_2026 <- function(data_roles,
                                 themes,
                                 prompt = "prompts/topic_assignment_data_role.md",
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
    prompts = as.list(data_roles),
    type = data_role_coding_type(codes = themes$code)
  ) |>
    tibble::as_tibble()
}

#' Run both stages and return tidy output ----

process_data_roles_2026 <- function(data_roles,
                                    model = "claude-opus-4-8") {
  data_roles <- trimws(data_roles)
  valid <- !is.na(data_roles) & nzchar(data_roles)

  discovered <- discover_data_role_themes_2026(
    data_roles = data_roles[valid], model = model
  )

  coded <- code_data_roles_2026(
    data_roles = data_roles[valid],
    themes = discovered$themes,
    model = model
  )

  ## One row per participant, themes collapsed to a string for CSV safety ----
  participants <- tibble::tibble(
    data_role = data_roles,
    primary_theme = NA_character_,
    engagement = NA_character_,
    confidence = NA_character_,
    reasoning = NA_character_,
    themes = NA_character_
  )

  ## Enums arrive as factors; keep them as labels, not integer codes ----
  participants$primary_theme[valid] <- as.character(coded$primary_theme)
  participants$engagement[valid] <- as.character(coded$engagement)
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
