#'
#' Generate a synthetic IBC registration-application dataset for the
#' Epidemiological Statistics session (data-concepts-applications/10-epi-stats).
#'
#' The scenario is anchored on the Financial Services Authority (FSA) in its role
#' as the official corporate registry for International Business Companies (IBCs).
#' Each row is one application, with fields drawn from the ICSP Application Form
#' (images/ICSP Application Form.pdf, pages 2-5): proposed company name, applicant
#' contact details, proposed service activity, company directors, compliance
#' officer(s), former names, financial details, proposed employment size, and
#' forecasted cash flows.
#'
#' Field names follow the convention: lower case, no spaces, short but
#' informative (snake_case).
#'
#' Signal built in for the exercises: applications reporting a higher capital
#' (`capital_usd`) tend to have a greater proposed employment size
#' (`employment_total`) -- a positive association for correlation / group
#' comparisons.
#'
#' Output: data/ibc_applications_2026.xlsx (sheet "applications").
#'
#' Requires the `writexl` package (add via `renv::install("writexl")`).
#'

library(writexl)

n <- 400

# ---- Value pools --------------------------------------------------------------
first_names <- c(
  "James", "David", "Wei", "Rajesh", "Ahmed", "Jean", "Pierre", "Thomas",
  "Michael", "Chen", "Vikram", "Mohammed", "Marie", "Sarah", "Li", "Priya",
  "Fatima", "Anne", "Claire", "Emma", "Mei", "Anita", "Aisha", "Nadia",
  "Sophie", "Lars", "Marco", "Daniel", "Grace", "Ingrid", "Giulia", "Rachel",
  "Olga", "Yuki", "Camille", "Elena", "Khalid", "Antoine", "Feng", "Layla"
)
surnames <- c(
  "Adams", "Botha", "Dubois", "Smith", "Sharma", "Wong", "Al-Farsi", "Rossi",
  "Muller", "Otieno", "Fernandez", "Naidoo", "Petrov", "Tanaka", "Bernard",
  "Hoareau", "Payet", "Rajapaksa", "Khan", "Ng", "Patel", "Nguyen", "Okafor",
  "Schneider", "Bianchi", "Larsson", "Mensah", "Da Silva", "Reddy", "Ali",
  "Laurent", "Zhang", "Suzuki", "Moradi", "Cousin", "Rose", "Lablache",
  "Confait", "Marengo", "Servina"
)
occupations <- c(
  "Company Director", "Accountant", "Lawyer", "Business Consultant",
  "Financial Advisor", "Entrepreneur", "Investment Manager",
  "Chartered Accountant", "Real Estate Developer", "Trader", "Banker",
  "Management Consultant", "Auditor", "Corporate Administrator", "Notary"
)
nationalities <- c(
  "Seychellois", "South African", "French", "British", "Indian", "Chinese",
  "Emirati", "Mauritian", "German", "Kenyan", "Italian", "American",
  "Singaporean", "Qatari", "Saudi", "Russian", "Sri Lankan", "Japanese",
  "Swiss", "Nigerian"
)
co_prefix <- c(
  "Azure", "Summit", "Meridian", "Global", "Coral", "Granite", "Horizon",
  "Pinnacle", "Atlas", "Orion", "Sapphire", "Vanguard", "Delta", "Nova",
  "Everest", "Crescent", "Baobab", "Indigo", "Zenith", "Cobalt"
)
co_type <- c(
  "Holdings", "International", "Global", "Ventures", "Trading", "Capital",
  "Group", "Enterprises", "Investments", "Partners"
)

USD_TO_SCR <- 14.2   # approximate exchange rate used for domestic expenditure

# ---- Build the dataset --------------------------------------------------------
set.seed(20260725)

# Reported capital of applicant (US$), heavy right skew, rounded to nearest 1000.
capital_usd <- round(rlnorm(n, meanlog = log(250000), sdlog = 1.0) / 1000) * 1000
capital_usd <- pmin(pmax(capital_usd, 50000), 10000000)

# SIGNAL: proposed employment size increases with reported capital.
# Model employment on a standardised log-capital scale, with noise so the
# association is clear but not deterministic.
logcap <- log10(capital_usd)
z      <- (logcap - mean(logcap)) / sd(logcap)
employment_total  <- round(pmax(1, 5 + 3.2 * z + rnorm(n, 0, 2.3)))

# Split total into locals and expatriates.
frac_local        <- runif(n, 0.35, 0.85)
employment_locals <- round(employment_total * frac_local)
employment_expats <- employment_total - employment_locals

# Forecasted cash flows (also scale with capital, but noisier).
annual_revenue_usd  <- round(capital_usd * runif(n, 0.4, 3.5) / 1000) * 1000
dom_expenditure_usd <- round(annual_revenue_usd * runif(n, 0.10, 0.55) / 1000) * 1000
dom_expenditure_scr <- round(dom_expenditure_usd * USD_TO_SCR)

# Categorical / descriptive fields.
service_type     <- sample(c("Corporate Services", "Trustee Services"),
                           n, replace = TRUE, prob = c(0.78, 0.22))
capital_source   <- sample(c("Owner Equity", "Shareholder Equity", "Loan"),
                           n, replace = TRUE, prob = c(0.45, 0.35, 0.20))
num_directors    <- sample(c(1L, 2L), n, replace = TRUE, prob = c(0.30, 0.70))
has_alt_officer  <- sample(c("Yes", "No"), n, replace = TRUE, prob = c(0.55, 0.45))
has_former_names <- sample(c("Yes", "No"), n, replace = TRUE, prob = c(0.18, 0.82))

applicant_name     <- paste(sample(first_names, n, replace = TRUE),
                            sample(surnames,    n, replace = TRUE))
compliance_officer <- paste(sample(first_names, n, replace = TRUE),
                            sample(surnames,    n, replace = TRUE))
occupation         <- sample(occupations,   n, replace = TRUE)
nationality        <- sample(nationalities, n, replace = TRUE)
company_name       <- paste(sample(co_prefix, n, replace = TRUE),
                            sample(co_type,   n, replace = TRUE), "Limited")

applications <- data.frame(
  app_id              = sprintf("IBC-2026-%04d", seq_len(n)),
  company_name        = company_name,
  applicant_name      = applicant_name,
  occupation          = occupation,
  nationality         = nationality,
  service_type        = service_type,
  num_directors       = num_directors,
  compliance_officer  = compliance_officer,
  has_alt_officer     = has_alt_officer,
  has_former_names    = has_former_names,
  capital_usd         = capital_usd,
  capital_source      = capital_source,
  employment_total    = employment_total,
  employment_locals   = employment_locals,
  employment_expats   = employment_expats,
  annual_revenue_usd  = annual_revenue_usd,
  dom_expenditure_usd = dom_expenditure_usd,
  dom_expenditure_scr = dom_expenditure_scr,
  stringsAsFactors    = FALSE
)

# ---- Write --------------------------------------------------------------------
writexl::write_xlsx(
  list(applications = applications),
  here::here("data", "ibc_applications_2026.xlsx")
)

# ---- Report -------------------------------------------------------------------
message(sprintf("ibc_applications_2026.xlsx | n=%d | fields=%d",
                nrow(applications), ncol(applications)))
message(sprintf("capital_usd: median $%s (range $%s - $%s)",
                format(median(capital_usd), big.mark = ","),
                format(min(capital_usd), big.mark = ","),
                format(max(capital_usd), big.mark = ",")))
message(sprintf("employment_total: median %d (range %d - %d)",
                median(employment_total), min(employment_total),
                max(employment_total)))
message(sprintf("SIGNAL check -> cor(log10 capital, employment_total) = %.2f",
                cor(logcap, employment_total)))
