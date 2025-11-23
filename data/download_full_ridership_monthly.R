# Download Complete MTA Subway Hourly Ridership Data for MANHATTAN ONLY (2024-2025)
# Uses API-level aggregation (SUM) to combine fare classes and payment methods
# Downloads data MONTH BY MONTH for complete coverage

library(tidyverse)
library(httr)
library(jsonlite)
library(lubridate)

# Create output directory
dir.create("data/mta_ridership_full", showWarnings = FALSE, recursive = TRUE)

# =============================================================================
# Configuration
# =============================================================================

mta_2020_2024_url <- "https://data.ny.gov/resource/wujg-7c2s.json"
mta_2025_url <- "https://data.ny.gov/resource/5wq4-mkjj.json"

chunk_size <- 50000  # Max records per API call

# =============================================================================
# Function to download data for a date range
# =============================================================================

download_ridership_chunk <- function(url, start_date, end_date, offset = 0) {
  query <- list(
    "$select" = "transit_timestamp, station_complex_id, station_complex, borough, SUM(ridership) as total_ridership",
    "$where" = sprintf("transit_timestamp between '%sT00:00:00' and '%sT23:59:59' AND borough = 'Manhattan'",
                       start_date, end_date),
    "$group" = "transit_timestamp, station_complex_id, station_complex, borough",
    "$limit" = chunk_size,
    "$offset" = offset,
    "$order" = "transit_timestamp"
  )

  response <- GET(url, query = query)

  if (status_code(response) == 200) {
    data <- fromJSON(content(response, as = "text", encoding = "UTF-8"))
    if (length(data) > 0) {
      return(as_tibble(data))
    }
  }
  return(NULL)
}

# =============================================================================
# Function to download all data for a date range with pagination
# =============================================================================

download_date_range <- function(url, start_date, end_date, label) {
  cat(sprintf("  %s... ", label))

  all_data <- list()
  offset <- 0
  chunk_num <- 1

  repeat {
    chunk_data <- download_ridership_chunk(url, start_date, end_date, offset)

    if (is.null(chunk_data) || nrow(chunk_data) == 0) {
      break
    }

    records_retrieved <- nrow(chunk_data)
    all_data[[chunk_num]] <- chunk_data

    if (records_retrieved < chunk_size) {
      break
    }

    offset <- offset + chunk_size
    chunk_num <- chunk_num + 1
    Sys.sleep(0.3)  # Be nice to the API
  }

  if (length(all_data) > 0) {
    combined_data <- bind_rows(all_data)
    cat(sprintf("%d records\n", nrow(combined_data)))
    return(combined_data)
  }

  cat("No data\n")
  return(NULL)
}

# =============================================================================
# Generate month periods
# =============================================================================

generate_months <- function(start_date_str, end_date_str) {
  start_date <- ymd(start_date_str)
  end_date <- ymd(end_date_str)

  # Get all first days of months in the range
  months <- seq(floor_date(start_date, "month"), end_date, by = "month")

  lapply(months, function(m) {
    month_end <- ceiling_date(m, "month") - days(1)
    # Don't go past the end date
    if (month_end > end_date) month_end <- end_date

    list(
      label = format(m, "%Y-%m"),
      start = format(m, "%Y-%m-%d"),
      end = format(month_end, "%Y-%m-%d")
    )
  })
}

# =============================================================================
# Download data month by month (Manhattan only)
# =============================================================================

cat("\n")
cat(strrep("=", 70), "\n")
cat("MTA SUBWAY HOURLY RIDERSHIP - MANHATTAN ONLY (2024-2025)\n")
cat("Using API aggregation (SUM) to combine fare classes and payment methods\n")
cat("Downloading by month for complete coverage\n")
cat(strrep("=", 70), "\n\n")

# Download 2024 data
cat("Downloading 2024 Manhattan data by month...\n")
months_2024 <- generate_months("2024-01-01", "2024-12-31")

all_data_2024 <- list()
for (i in seq_along(months_2024)) {
  period <- months_2024[[i]]
  data <- download_date_range(mta_2020_2024_url, period$start, period$end, period$label)
  if (!is.null(data)) {
    all_data_2024[[i]] <- data
  }
}

if (length(all_data_2024) > 0) {
  cat("\nCombining 2024 data...\n")
  combined_2024 <- bind_rows(all_data_2024)
  write_csv(combined_2024, "data/mta_ridership_full/ridership_2024_manhattan.csv")
  cat(sprintf("✓ Saved %d records to ridership_2024_manhattan.csv\n", nrow(combined_2024)))
}

# Download 2025 data
cat("\nDownloading 2025 Manhattan data by month...\n")
months_2025 <- generate_months("2025-01-01", format(Sys.Date(), "%Y-%m-%d"))

all_data_2025 <- list()
for (i in seq_along(months_2025)) {
  period <- months_2025[[i]]
  data <- download_date_range(mta_2025_url, period$start, period$end, period$label)
  if (!is.null(data)) {
    all_data_2025[[i]] <- data
  }
}

if (length(all_data_2025) > 0) {
  cat("\nCombining 2025 data...\n")
  combined_2025 <- bind_rows(all_data_2025)
  write_csv(combined_2025, "data/mta_ridership_full/ridership_2025_manhattan.csv")
  cat(sprintf("✓ Saved %d records to ridership_2025_manhattan.csv\n", nrow(combined_2025)))
}

# =============================================================================
# Summary
# =============================================================================

cat("\n")
cat(strrep("=", 70), "\n")
cat("DOWNLOAD COMPLETE\n")
cat(strrep("=", 70), "\n\n")

files <- list.files("data/mta_ridership_full", pattern = "*manhattan.csv", full.names = TRUE)
cat("Downloaded files:\n")
total_size <- 0
for (file in files) {
  size_mb <- file.size(file) / 1024 / 1024
  total_size <- total_size + size_mb
  cat(sprintf("  - %s (%.1f MB)\n", basename(file), size_mb))
}
cat(sprintf("\nTotal size: %.1f MB\n", total_size))

cat("\nTo load all Manhattan data:\n")
cat("  manhattan_ridership <- bind_rows(\n")
cat("    read_csv('data/mta_ridership_full/ridership_2024_manhattan.csv'),\n")
cat("    read_csv('data/mta_ridership_full/ridership_2025_manhattan.csv')\n")
cat("  )\n")
