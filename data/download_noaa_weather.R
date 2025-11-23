# Download NOAA GHCN-Daily Weather Data for Central Park Station
# Station ID: GHCND:USW00094728

library(tidyverse)
library(httr)
library(jsonlite)
library(lubridate)

# NOAA API token
noaa_token <- "VjwNPvcKVkuXcoBCKeZpIiQyfcfEFjQO"

# NOAA API endpoint
noaa_url <- "https://www.ncei.noaa.gov/cdo-web/api/v2/data"

cat("Downloading NOAA GHCN-Daily weather data for Central Park Station...\n")
cat("Station: GHCND:USW00094728\n")
cat("Period: 2020-01-01 to 2025-11-05\n\n")

# Function to download data for a given date range
download_period <- function(start_date, end_date, token) {
  params <- list(
    datasetid = "GHCND",
    stationid = "GHCND:USW00094728",
    startdate = start_date,
    enddate = end_date,
    datatypeid = "TMAX,PRCP,SNOW",
    units = "standard",
    limit = 1000
  )

  response <- GET(
    noaa_url,
    query = params,
    add_headers(token = token)
  )

  if (status_code(response) == 200) {
    data <- fromJSON(content(response, as = "text", encoding = "UTF-8"))
    if (!is.null(data$results)) {
      return(as_tibble(data$results))
    }
  }
  return(NULL)
}

# Function to download data for a given year in two halves to avoid 1000 record limit
download_year <- function(year, token) {
  cat(sprintf("Downloading data for %d...\n", year))

  # Download first half (Jan-Jun)
  h1 <- download_period(
    sprintf("%d-01-01", year),
    sprintf("%d-06-30", year),
    token
  )
  Sys.sleep(0.3)

  # Download second half (Jul-Dec)
  h2 <- download_period(
    sprintf("%d-07-01", year),
    sprintf("%d-12-31", year),
    token
  )

  year_data <- bind_rows(h1, h2)

  if (nrow(year_data) > 0) {
    cat(sprintf("  ✓ Downloaded %d records\n", nrow(year_data)))
    return(year_data)
  } else {
    cat("  ! No data returned\n")
    return(NULL)
  }
}

# Download data for each year from 2020 to 2025
all_data <- list()
for (year in 2020:2025) {
  year_data <- download_year(year, noaa_token)
  if (!is.null(year_data)) {
    all_data[[as.character(year)]] <- year_data
  }
  Sys.sleep(0.5)  # Be nice to the API
}

# Combine all years
if (length(all_data) > 0) {
  weather_data <- bind_rows(all_data)

  # Pivot wider to have one row per date with columns for each variable
  weather_wide <- weather_data %>%
    select(date, datatype, value) %>%
    pivot_wider(
      names_from = datatype,
      values_from = value,
      values_fn = first  # In case of duplicates, take first value
    )

  # Save both formats
  write_csv(weather_data, "data/weather/central_park_weather_long.csv")
  write_csv(weather_wide, "data/weather/central_park_weather_wide.csv")

  cat("\n" %+% strrep("=", 70) %+% "\n")
  cat("WEATHER DATA DOWNLOAD COMPLETE\n")
  cat(strrep("=", 70) %+% "\n")
  cat(sprintf("Total records: %d\n", nrow(weather_data)))
  cat(sprintf("Date range: %s to %s\n", min(weather_data$date), max(weather_data$date)))
  cat("\nSaved to:\n")
  cat("  - data/weather/central_park_weather_long.csv (long format)\n")
  cat("  - data/weather/central_park_weather_wide.csv (wide format)\n")
  cat("\nVariables:\n")
  cat("  - TMAX: Maximum temperature (°F)\n")
  cat("  - PRCP: Precipitation (inches)\n")
  cat("  - SNOW: Snowfall (inches)\n")
} else {
  cat("\n✗ No data was downloaded successfully.\n")
}
