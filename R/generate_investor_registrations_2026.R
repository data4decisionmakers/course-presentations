#'
#' Generate a synthetic event-registration dataset for the Epidemiological
#' Statistics session (data-concepts-applications/10-epi-stats).
#'
#' The scenario is anchored on a participant who is a marketing executive at the
#' Seychelles Investment Board (SIB) and plans events for the Board. The data
#' emulate registrations for an SIB-hosted event aimed at current and
#' prospective investors in Seychelles.
#'
#' Fields: name, sex, nationality, position, company, country, dietary, investor.
#'
#' Two signals are built in for the exercises:
#'   (1) sex -> position: males are more likely to hold positions of power
#'       (executive roles); females are more likely to be in middle-manager /
#'       administrative roles.
#'   (2) sex -> dietary: females are more likely to be vegan/vegetarian.
#'
#' `position` is drawn from two non-overlapping pools so it can be classified in
#' Excel with the same keyword approach used for the complaints data:
#'   * every EXECUTIVE title contains >= 1 word from EXEC_KEYWORDS, and
#'   * no MIDDLE/ADMIN title contains any word from EXEC_KEYWORDS.
#' `dietary` uses a fixed value set; VEG_VALUES marks the vegan/vegetarian group.
#' Both guarantees are asserted before the file is written.
#'
#' Output: data/investor_registrations_2026.xlsx, with two sheets
#' ("registrations" and "keywords").
#'
#' Requires the `writexl` package (add via `renv::install("writexl")`).
#'

library(writexl)

n <- 300

# ---- Position classification --------------------------------------------------
# Excel SEARCH is a case-insensitive substring match. Keywords are chosen to be
# "contained": none is a substring of any middle/administrative title (note that
# bare abbreviations like "COO" are avoided because they collide with words such
# as "Coordinator", and bare "Executive" is avoided because of "Marketing
# Executive", which is a middle-level role).
EXEC_KEYWORDS <- c(
  "Chief", "President", "Managing Director", "Executive Director",
  "Founder", "Owner", "Partner", "Chairman", "Chairperson"
)

executive_positions <- c(
  "Chief Executive Officer", "Chief Financial Officer", "Chief Operating Officer",
  "Chief Investment Officer", "Chief Commercial Officer", "Managing Director",
  "Executive Director", "President", "Vice President", "Founder", "Co-Founder",
  "Company Owner", "Managing Partner", "Senior Partner", "Chairman", "Chairperson"
)

middle_positions <- c(
  "Marketing Executive", "Marketing Manager", "Sales Manager",
  "Operations Manager", "Project Coordinator", "Administrative Officer",
  "Finance Officer", "Business Analyst", "Investment Analyst", "Account Manager",
  "Communications Officer", "Events Coordinator", "Human Resources Manager",
  "Compliance Officer", "Relationship Manager", "Assistant Manager",
  "Procurement Officer", "Senior Accountant"
)

# ---- Dietary (fixed value set) ------------------------------------------------
# VEG_VALUES form the vegan/vegetarian group; the rest are non-veg.
VEG_VALUES     <- c("Vegan", "Vegetarian")
non_veg_values <- c("None", "Halal", "Kosher", "Pescatarian",
                    "Gluten-free", "Nut allergy")
dietary_values <- c(VEG_VALUES, non_veg_values)

# ---- Nationalities and (aligned) company home countries -----------------------
nationalities <- c(
  "Seychellois", "South African", "French", "British", "Indian", "Chinese",
  "Emirati", "Mauritian", "German", "Kenyan", "Italian", "American",
  "Singaporean", "Qatari", "Saudi", "Russian", "Sri Lankan", "Japanese",
  "Swiss", "Nigerian"
)
countries <- c(
  "Seychelles", "South Africa", "France", "United Kingdom", "India", "China",
  "United Arab Emirates", "Mauritius", "Germany", "Kenya", "Italy",
  "United States", "Singapore", "Qatar", "Saudi Arabia", "Russia",
  "Sri Lanka", "Japan", "Switzerland", "Nigeria"
)

# ---- Name pools (deliberately international) -----------------------------------
male_first <- c(
  "James", "David", "Wei", "Rajesh", "Ahmed", "Jean", "Pierre", "Thomas",
  "Michael", "Chen", "Vikram", "Mohammed", "Kwame", "Lars", "Marco", "Daniel",
  "Ravi", "Hassan", "Sanjay", "Liam", "Andre", "Nikolai", "Hiroshi", "Olivier",
  "Emmanuel", "Sunil", "Khalid", "Peter", "Antoine", "Feng"
)
female_first <- c(
  "Marie", "Sarah", "Li", "Priya", "Fatima", "Anne", "Claire", "Emma", "Mei",
  "Anita", "Aisha", "Nadia", "Sophie", "Lakshmi", "Grace", "Ingrid", "Giulia",
  "Rachel", "Divya", "Olga", "Yuki", "Camille", "Amina", "Zara", "Elena",
  "Rekha", "Layla", "Julia", "Chantal", "Ling"
)
surnames <- c(
  "Adams", "Botha", "Dubois", "Smith", "Sharma", "Wong", "Al-Farsi", "Rossi",
  "Muller", "Otieno", "Fernandez", "Naidoo", "Petrov", "Tanaka", "Bernard",
  "Hoareau", "Payet", "Rajapaksa", "Khan", "Ng", "Patel", "Nguyen", "Okafor",
  "Schneider", "Bianchi", "Larsson", "Mensah", "Da Silva", "Reddy", "Ali",
  "Laurent", "Zhang", "Suzuki", "Moradi", "Cousin", "Rose", "Lablache",
  "Confait", "Marengo", "Servina"
)

# ---- Company name generator ---------------------------------------------------
co_prefix <- c(
  "Azure", "Summit", "Meridian", "Global", "Coral", "Granite", "Horizon",
  "Pinnacle", "Atlas", "Orion", "Sapphire", "Vanguard", "Delta", "Nova",
  "Everest", "Crescent", "Baobab", "Indigo", "Zenith", "Cobalt"
)
co_type <- c(
  "Capital", "Investments", "Holdings", "Ventures", "Partners", "Group",
  "Advisory", "Asset Management", "Development", "Resources"
)

# ---- Coverage assertions ------------------------------------------------------
contains_exec <- function(x) {
  Reduce(`|`, lapply(EXEC_KEYWORDS, function(k) grepl(k, x, ignore.case = TRUE)))
}
stopifnot(all(contains_exec(executive_positions)))     # every exec is catchable
if (any(contains_exec(middle_positions))) {
  bad <- middle_positions[contains_exec(middle_positions)]
  stop("Middle/admin title matches an executive keyword:\n",
       paste(bad, collapse = "\n"))
}

# ---- Build the dataset --------------------------------------------------------
set.seed(20260724)

# Sex (slightly more male, reflecting the investor cohort and making the
# position signal visible).
sex <- sample(c("Male", "Female"), n, replace = TRUE, prob = c(0.55, 0.45))

# Signal 1: sex -> position seniority.
p_exec   <- ifelse(sex == "Male", 0.55, 0.25)
is_exec  <- runif(n) < p_exec
position <- ifelse(
  is_exec,
  sample(executive_positions, n, replace = TRUE),
  sample(middle_positions,    n, replace = TRUE)
)

# Signal 2: sex -> dietary (females more likely vegan/vegetarian).
p_veg   <- ifelse(sex == "Female", 0.35, 0.12)
is_veg  <- runif(n) < p_veg
dietary <- ifelse(
  is_veg,
  sample(VEG_VALUES,     n, replace = TRUE),
  sample(non_veg_values, n, replace = TRUE, prob = c(0.45, 0.15, 0.10, 0.12, 0.10, 0.08))
)

# Name (consistent with sex).
first <- ifelse(sex == "Male",
                sample(male_first,   n, replace = TRUE),
                sample(female_first, n, replace = TRUE))
name  <- paste(first, sample(surnames, n, replace = TRUE))

# Nationality and company home country (loosely aligned: 65% share an index).
nat_idx     <- sample(seq_along(nationalities), n, replace = TRUE)
same        <- runif(n) < 0.65
country_idx <- ifelse(same, nat_idx,
                      sample(seq_along(countries), n, replace = TRUE))
nationality <- nationalities[nat_idx]
country     <- countries[country_idx]

# Company and investor status.
company  <- paste(sample(co_prefix, n, replace = TRUE),
                  sample(co_type,   n, replace = TRUE))
investor <- sample(c("Current investor", "Prospective investor"),
                   n, replace = TRUE, prob = c(0.4, 0.6))

registrations <- data.frame(
  name        = name,
  sex         = sex,
  nationality = nationality,
  position    = position,
  company     = company,
  country     = country,
  dietary     = dietary,
  investor    = investor,
  stringsAsFactors = FALSE
)

# ---- Keyword / reference sheet (padded to equal length) -----------------------
m <- max(length(EXEC_KEYWORDS), length(VEG_VALUES))
keyword_sheet <- data.frame(
  executive_keyword     = c(EXEC_KEYWORDS, rep(NA, m - length(EXEC_KEYWORDS))),
  vegan_vegetarian_value = c(VEG_VALUES,   rep(NA, m - length(VEG_VALUES))),
  stringsAsFactors = FALSE
)

# ---- Write --------------------------------------------------------------------
writexl::write_xlsx(
  list(registrations = registrations, keywords = keyword_sheet),
  here::here("data", "investor_registrations_2026.xlsx")
)

# ---- Report -------------------------------------------------------------------
exec_flag <- contains_exec(registrations$position)
veg_flag  <- registrations$dietary %in% VEG_VALUES
message(sprintf("investor_registrations_2026.xlsx | n=%d", nrow(registrations)))
message("Executive share by sex:")
print(round(tapply(exec_flag, registrations$sex, mean), 2))
message("Vegan/vegetarian share by sex:")
print(round(tapply(veg_flag, registrations$sex, mean), 2))
message("Position keyword check: every executive catchable, zero false positives.")
