# Download Historical NYC Permitted Events by Month (2024-2025)
# This downloads data MONTH BY MONTH to avoid pagination issues
#
# FILTERS FOR LARGE EVENTS ONLY (likely 100+ people):
#   - Parades
#   - Athletic Races/Tours (marathons, bike tours)
#   - Street Events (street fairs, festivals)
#   - Sidewalk Sales
#   - Any event with Full Street Closure
#
# EXCLUDES small events:
#   - Sport - Youth/Adult (little league, sports leagues)
#   - Production Events (film shoots)
#   - Farmers Markets
#   - Most Special Events (small park events)

library(tidyverse)
library(httr)
library(jsonlite)
library(lubridate)

# Create data subdirectory
dir.create("data/events", showWarnings = FALSE, recursive = TRUE)

cat("\n")
cat(strrep("=", 70), "\n")
cat("DOWNLOADING LARGE NYC EVENTS BY MONTH (2024-2025)\n")
cat("Filtering for events likely to impact subway ridership (100+ people)\n")
cat(strrep("=", 70), "\n\n")

# Historical events API endpoint
events_url <- "https://data.cityofnewyork.us/resource/bkfu-528j.json"

# Generate month ranges for 2024-2025
months <- seq(as.Date("2024-01-01"), as.Date("2025-10-31"), by = "month")

all_monthly_events <- list()

for (i in seq_along(months)) {
  start_date <- months[i]
  end_date <- ceiling_date(start_date, "month") - days(1)

  # Make sure end_date doesn't go beyond Oct 2025
  if (end_date > as.Date("2025-10-31")) {
    end_date <- as.Date("2025-10-31")
  }

  cat(sprintf("Downloading %s... ", format(start_date, "%Y-%m")))

  # Download all events for this month
  month_events <- list()
  offset <- 0
  chunk_size <- 50000
  chunk_num <- 1

  repeat {
    # Filter for "big events" only - likely to impact subway ridership
    # Include: Parades, Athletic Races, Street Events, or Full Street Closures
    # Exclude: Small sports, production events, farmers markets
    where_clause <- sprintf(
      "start_date_time >= '%sT00:00:00' AND start_date_time <= '%sT23:59:59' AND (%s)",
      start_date,
      end_date,
      paste(
        "event_type = 'Parade'",
        "event_type = 'Athletic Race / Tour'",
        "event_type = 'Street Event'",
        "event_type = 'Sidewalk Sale'",
        "street_closure_type = 'Full Street Closure'",
        sep = " OR "
      )
    )

    events_query <- list(
      "$where" = where_clause,
      "$limit" = chunk_size,
      "$offset" = offset,
      "$order" = "start_date_time"
    )

    events_response <- GET(events_url, query = events_query)
    response_text <- content(events_response, as = "text", encoding = "UTF-8")

    if (nchar(response_text) == 0 || response_text == "[]") {
      break
    }

    events_raw <- tryCatch({
      fromJSON(response_text)
    }, error = function(e) {
      return(NULL)
    })

    if (is.null(events_raw) || length(events_raw) == 0) {
      break
    }

    records_retrieved <- nrow(as_tibble(events_raw))
    month_events[[chunk_num]] <- as_tibble(events_raw)

    if (records_retrieved < chunk_size) {
      break
    }

    offset <- offset + chunk_size
    chunk_num <- chunk_num + 1
    Sys.sleep(0.2)
  }

  if (length(month_events) > 0) {
    month_combined <- bind_rows(month_events)
    all_monthly_events[[i]] <- month_combined
    cat(sprintf("%s events\n", format(nrow(month_combined), big.mark = ",")))
  } else {
    cat("0 events\n")
  }

  Sys.sleep(0.3)
}

# Combine all months
if (length(all_monthly_events) > 0) {
  events_combined <- bind_rows(all_monthly_events)
  write_csv(events_combined, "data/events/nyc_large_events_2024_2025.csv")

  cat("\n")
  cat(sprintf("✓ Saved %s large events to data/events/nyc_large_events_2024_2025.csv\n",
              format(nrow(events_combined), big.mark = ",")))

  # Summary statistics
  events_combined <- events_combined %>%
    mutate(start_date = as.Date(start_date_time))

  cat("\nSummary:\n")
  cat(sprintf("   Date range: %s to %s\n",
              min(events_combined$start_date, na.rm = TRUE),
              max(events_combined$start_date, na.rm = TRUE)))

  # Monthly distribution
  cat("\n   Events by month:\n")
  monthly_counts <- events_combined %>%
    mutate(month = format(start_date, "%Y-%m")) %>%
    count(month, sort = FALSE)

  for (i in 1:min(nrow(monthly_counts), 12)) {
    cat(sprintf("      %s: %s\n",
                monthly_counts$month[i],
                format(monthly_counts$n[i], big.mark = ",")))
  }

  if (nrow(monthly_counts) > 12) {
    cat(sprintf("      ... and %d more months\n", nrow(monthly_counts) - 12))
  }

  # Count by borough
  if ("event_borough" %in% names(events_combined)) {
    borough_counts <- events_combined %>%
      mutate(borough_clean = case_when(
        str_detect(tolower(event_borough), "manhattan") ~ "Manhattan",
        str_detect(tolower(event_borough), "brooklyn") ~ "Brooklyn",
        str_detect(tolower(event_borough), "queens") ~ "Queens",
        str_detect(tolower(event_borough), "bronx") ~ "Bronx",
        str_detect(tolower(event_borough), "staten") ~ "Staten Island",
        TRUE ~ "Other"
      )) %>%
      count(borough_clean, sort = TRUE)

    cat("\n   Events by borough:\n")
    for (i in 1:nrow(borough_counts)) {
      cat(sprintf("      %s: %s\n",
                  borough_counts$borough_clean[i],
                  format(borough_counts$n[i], big.mark = ",")))
    }

    manhattan_events <- sum(str_detect(tolower(events_combined$event_borough), "manhattan"), na.rm = TRUE)
    cat(sprintf("\n   ✓ Manhattan events: %s\n", format(manhattan_events, big.mark = ",")))
  }

  # Top event types
  if ("event_type" %in% names(events_combined)) {
    cat("\n   Top 5 event types:\n")
    top_types <- events_combined %>%
      filter(!is.na(event_type)) %>%
      count(event_type, sort = TRUE) %>%
      head(5)

    for (i in 1:nrow(top_types)) {
      cat(sprintf("      %s: %s\n",
                  top_types$event_type[i],
                  format(top_types$n[i], big.mark = ",")))
    }
  }

} else {
  cat("   ! Warning: No events data retrieved\n")
}

cat("\n")
cat(strrep("=", 70), "\n")
cat("DOWNLOAD COMPLETE\n")
cat(strrep("=", 70), "\n\n")

if (file.exists("data/events/nyc_large_events_2024_2025.csv")) {
  events_size <- file.size("data/events/nyc_large_events_2024_2025.csv") / 1024 / 1024
  cat(sprintf("Downloaded file:\n  - data/events/nyc_large_events_2024_2025.csv (%.1f MB)\n", events_size))
}

cat("\nData Source:\n")
cat("  NYC Permitted Event Information - Historical\n")
cat("  https://data.cityofnewyork.us/City-Government/NYC-Permitted-Event-Information-Historical/bkfu-528j\n")
