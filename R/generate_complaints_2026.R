#'
#' Generate synthetic customer-service feedback datasets for the
#' Epidemiological Statistics session (data-concepts-applications/10-epi-stats).
#'
#' The data emulate feedback (mainly complaints) received by the customer
#' service department of a government ministry in Seychelles. Two versions are
#' produced, each written as an XLSX with two sheets ("complaints" and
#' "keywords"):
#'
#'   * complaints_random.xlsx - no signal; demographics, location and sentiment
#'     are independent.
#'   * complaints_signal.xlsx - two built-in signals for the exercises:
#'       (1) older clients (60+) are slightly more likely to be positive, and
#'       (2) more feedback volume comes from Central Mahe (Greater Victoria)
#'           districts.
#'
#' The feedback field is ~90% clearly NEGATIVE complaints and ~10% clearly
#' NEUTRAL/POSITIVE, using ministry-agnostic language. It is tightened so that a
#' basic keyword match in Excel classifies every record correctly:
#'   * every negative record contains >= 1 word from NEG_KEYWORDS, and
#'   * no positive/neutral record contains any word from NEG_KEYWORDS.
#' Both guarantees are asserted before the files are written.
#'
#' Requires the `writexl` package (add via `renv::install("writexl")`).
#'

library(writexl)

n <- 500

# ---- Seychelles districts (26 official administrative districts) -------------
districts <- c(
  "Anse aux Pins", "Anse Boileau", "Anse Etoile", "Anse Royale", "Au Cap",
  "Baie Lazare", "Baie Sainte Anne", "Beau Vallon", "Bel Air", "Bel Ombre",
  "Cascade", "English River", "Glacis", "Grand Anse Mahe", "Grand Anse Praslin",
  "La Digue", "La Riviere Anglaise", "Les Mamelles", "Mont Buxton", "Mont Fleuri",
  "Plaisance", "Pointe Larue", "Port Glaud", "Roche Caiman", "Saint Louis",
  "Takamaka"
)

# Central Mahe (Greater Victoria area) districts, over-represented in the
# signal version.
central_mahe <- c(
  "Bel Air", "English River", "La Riviere Anglaise", "Les Mamelles",
  "Mont Buxton", "Mont Fleuri", "Plaisance", "Roche Caiman", "Saint Louis",
  "Cascade"
)

# ---- Curated NEGATIVE keyword list (what participants search for) ------------
# Excel SEARCH is a case-insensitive substring match, so e.g. "waste" also
# catches "wasted", and "poor" also catches "Poorly".
NEG_KEYWORDS <- c(
  "unacceptable", "rude", "disappointed", "terrible", "waste", "frustrating",
  "unhelpful", "worst", "disorganised", "inefficient", "disgraceful",
  "overcrowded", "shameful", "delay", "poor", "impatient", "condescending",
  "cancelled", "incompetent", "careless", "ignored", "unprofessional",
  "overcharged", "dishonest", "useless", "disrespectful", "pending", "excuses",
  "slow", "filthy", "broken", "miserable", "ridiculous", "complaint", "chaos",
  "abrupt", "unfriendly", "infuriating", "incorrect", "contempt", "hopeless",
  "dismissive", "outrageous"
)

# Positive/neutral reference keywords (not used by the classify formula, which
# only needs negatives; provided for teaching). Chosen so none is a substring
# of any negative record.
POS_KEYWORDS <- c(
  "excellent", "satisfied", "pleasant", "wonderful", "appreciate", "courteous",
  "welcoming", "thank", "smooth", "kindly", "prompt", "no issue",
  "uneventful", "as expected", "neutral feedback"
)

# ---- Feedback text pools (tightened: every negative has a curated keyword) ---
negative <- c(
  "I waited over three hours at the counter and no one bothered to help me. Absolutely unacceptable service.",
  "The staff were extremely rude and dismissive when I asked a simple question. Very disappointed.",
  "I have come back four times now and my request is still not processed. This is a terrible waste of my time.",
  "No one answers the phone and the queue moves at a snail's pace. Frustrating and poorly organised.",
  "The officer was unhelpful and made me feel like a nuisance. Worst experience I have had with this office.",
  "I was passed from one desk to another with no clear answer. Completely disorganised and inefficient.",
  "They lost my paperwork and blamed me for it. Disgraceful handling of a citizen's documents.",
  "The waiting area was overcrowded and the staff kept disappearing on long breaks. Shameful.",
  "I submitted my forms two months ago and still received no response. This delay is completely unacceptable.",
  "The counter closed early without any notice while dozens of us were still waiting. Very poor service.",
  "The person serving me was impatient and spoke to me in a condescending, rude manner.",
  "My appointment was cancelled last minute with no explanation and no apology. Terrible customer care.",
  "I called ten times and each time I was put on hold and then disconnected. Utterly frustrating.",
  "The information they gave me was wrong and I had to redo everything. Incompetent and careless.",
  "There was no clear signage and no one to guide us. I wasted an entire morning going in circles.",
  "Staff were chatting among themselves and ignored the long line of people waiting. Unprofessional.",
  "I was overcharged and when I complained they refused to explain the fees. Dishonest and unhelpful.",
  "The online system kept crashing and the help desk simply told me to try again later. Useless.",
  "After queueing for two hours I was told I was in the wrong line. Poorly handled and frustrating.",
  "The officer lost patience with an elderly woman and was openly disrespectful. I was appalled.",
  "My case has been pending for weeks with no updates. Every follow-up is met with excuses and delays.",
  "The service was painfully slow and the staff seemed completely uninterested in helping anyone.",
  "I was given three different answers by three different officers. Utterly incompetent and confusing.",
  "The toilets were filthy, the air conditioning was broken, and staff did not care. A miserable experience.",
  "They demanded documents that were never mentioned before, forcing me to come back yet again. Ridiculous.",
  "I felt completely ignored. The staff avoided eye contact and pretended not to see the queue growing.",
  "My complaint from last month was never even acknowledged. This office does not care about the public.",
  "The parking was a nightmare and inside it was chaos with no proper queue system. Badly managed.",
  "The officer was abrupt, unfriendly and clearly wanted me gone as fast as possible. Very rude.",
  "I took a day off work only to be told the system was down. No apology, no alternative. Infuriating.",
  "Every time I visit there is a new excuse for the delay. The service is slow and beyond frustrating.",
  "The staff gave me incorrect directions and I ended up wasting hours. Careless and unhelpful.",
  "I was treated with contempt when I asked for clarification. The attitude at the front desk was disgraceful.",
  "Hours of waiting and then they closed the window right in front of me. Disgraceful treatment.",
  "The whole process was needlessly complicated and no one was willing to explain anything. Confusing and unhelpful.",
  "They kept losing track of my file and asked me to resubmit the same documents three times. Hopeless.",
  "The receptionist was dismissive and rolled her eyes at my questions. Extremely unprofessional.",
  "Nobody follows up on anything. My matter has been stuck for ages with zero communication. Simply unacceptable.",
  "I was shouted at for standing in the wrong spot when there were no signs anywhere. Outrageous.",
  "The service was slow, the staff were unfriendly, and my problem is still unresolved. Deeply disappointed."
)

positive <- c(
  "The staff were friendly and helpful, and my request was handled quickly. Excellent service, thank you!",
  "I was pleasantly surprised by how efficient and professional the officer was. Very satisfied.",
  "Great experience overall. The queue moved smoothly and everyone was courteous and kind.",
  "Thank you for the prompt and helpful assistance. The officer went out of their way to help me.",
  "The service was smooth and the staff were polite and well organised. I appreciate the good work.",
  "I just wanted to note the time and location of my visit for my own records. No issue to report.",
  "This is a general enquiry about opening hours; the visit itself was fine and uneventful.",
  "The officer was patient and clearly explained everything. A pleasant and efficient experience.",
  "Wonderful service today. Quick, friendly and professional. Thank you to the whole team.",
  "I am writing simply to confirm that my appointment was completed. Everything went as expected.",
  "Very satisfied with the helpful staff and the fast, well-organised process. Highly appreciated.",
  "The front desk was welcoming and my paperwork was processed promptly. Excellent job.",
  "Neutral feedback: I visited to ask a routine question and received a clear, adequate answer.",
  "Impressed by the professionalism and courtesy of the officer who assisted me. Thank you very much.",
  "Everything was handled efficiently and kindly. A genuinely positive and pleasant experience."
)

# ---- Coverage assertions -----------------------------------------------------
contains_neg <- function(x) {
  Reduce(`|`, lapply(NEG_KEYWORDS, function(k) grepl(k, x, ignore.case = TRUE)))
}
stopifnot(all(contains_neg(negative)))          # every negative is catchable
if (any(contains_neg(positive))) {
  bad <- positive[contains_neg(positive)]
  stop("Positive record matches a negative keyword:\n", paste(bad, collapse = "\n"))
}

# ---- Helper: business-hours timestamps (Mon-Fri, 08:00-16:30) ----------------
make_timestamps <- function(n) {
  start <- as.POSIXct("2026-01-05 08:00:00", tz = "Indian/Mahe")
  end   <- as.POSIXct("2026-07-22 16:30:00", tz = "Indian/Mahe")
  t <- sort(as.POSIXct(runif(n, as.numeric(start), as.numeric(end)),
                       origin = "1970-01-01", tz = "Indian/Mahe"))
  d  <- as.Date(t, tz = "Indian/Mahe")
  wd <- as.integer(format(t, "%u"))              # 1 = Mon ... 7 = Sun
  d[wd == 6] <- d[wd == 6] + 2                   # Saturday -> Monday
  d[wd == 7] <- d[wd == 7] + 1                   # Sunday   -> Monday
  secs <- round(runif(length(t), 0, 8.5 * 3600))
  as.POSIXct(paste(d, "08:00:00"), tz = "Indian/Mahe") + secs
}

# ---- Builder -----------------------------------------------------------------
build <- function(signal) {
  sex <- sample(c("Female", "Male"), n, replace = TRUE, prob = c(0.52, 0.48))
  age <- pmin(pmax(round(rnorm(n, mean = 41, sd = 14)), 18), 84)

  if (signal) {
    w <- ifelse(districts %in% central_mahe, 3, 1)
    location <- sample(districts, n, replace = TRUE, prob = w)
  } else {
    location <- sample(districts, n, replace = TRUE)
  }

  timestamp <- make_timestamps(n)

  is_neg   <- runif(n) < 0.90
  feedback <- character(n)
  feedback[is_neg]  <- sample(negative, sum(is_neg),  replace = TRUE)
  feedback[!is_neg] <- sample(positive, sum(!is_neg), replace = TRUE)

  if (signal) {
    nudge <- (age >= 60) & (runif(n) < 0.30)      # older clients slightly happier
    feedback[nudge] <- sample(positive, sum(nudge), replace = TRUE)
  }

  data.frame(
    id        = sprintf("CS-2026-%04d", seq_len(n)),
    timestamp = format(timestamp, "%Y-%m-%d %H:%M:%S"),
    age       = age,
    sex       = sex,
    location  = location,
    feedback  = feedback,
    stringsAsFactors = FALSE
  )
}

# ---- Keyword sheet (padded to equal length) ----------------------------------
m <- max(length(NEG_KEYWORDS), length(POS_KEYWORDS))
keyword_sheet <- data.frame(
  negative_keyword = c(NEG_KEYWORDS, rep(NA, m - length(NEG_KEYWORDS))),
  positive_keyword = c(POS_KEYWORDS, rep(NA, m - length(POS_KEYWORDS))),
  stringsAsFactors = FALSE
)

write_both <- function(df, path) {
  writexl::write_xlsx(list(complaints = df, keywords = keyword_sheet), path)
}

# ---- Generate and write ------------------------------------------------------
# Seeds fix the two datasets so they are reproducible.
set.seed(20260723)
random_data <- build(signal = FALSE)

set.seed(731982)
signal_data <- build(signal = TRUE)

write_both(random_data, here::here("data", "complaints_random.xlsx"))
write_both(signal_data, here::here("data", "complaints_signal.xlsx"))

# ---- Report ------------------------------------------------------------------
report <- function(df, name) {
  neg_hit <- contains_neg(df$feedback)
  message(sprintf(
    "%s | n=%d | keyword-flagged NEGATIVE=%d (%.0f%%) | central Mahe=%d (%.0f%%)",
    name, nrow(df), sum(neg_hit), 100 * mean(neg_hit),
    sum(df$location %in% central_mahe), 100 * mean(df$location %in% central_mahe)
  ))
}
report(random_data, "complaints_random.xlsx")
report(signal_data, "complaints_signal.xlsx")
