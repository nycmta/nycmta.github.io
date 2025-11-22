# The Pulse of NYC: Weather, Events, and the Subway

## Project Overview

This project analyzes how **extreme weather** and **mega-events** impact NYC subway ridership at the station level. By examining over 2 million hourly ridership records from January 2024 to October 2025, we uncover hidden patterns in Manhattan's daily commute.

**Course:** P8105 Data Science I | Fall 2025

## Team Members

- William M. Donovan (wd2328)
- Hantang Qin (hq2229)
- Yongyan Liu (yl6107)
- Yijun Wang (yw4664)
- Heng Hu (hh2648)

## Project Website

**Website URL:** https://nycmta.github.io

**GitHub Repository:** https://github.com/nycmta/nycmta.github.io

## Key Findings

Our analysis presents four data stories:

1. **The Goldilocks Zone** - How temperature and precipitation jointly affect ridership
2. **The Event Blast Radius** - Station-level ridership changes during major NYC events
3. **Station Personalities** - Classifying stations as Residential vs Commercial based on hourly patterns
4. **Rain Sensitivity by Hour** - When commuters are most likely to avoid the subway due to rain

## Repository Structure

```
nycmta/
├── index.Rmd              # Homepage
├── model.Rmd              # Analysis (Four Stories)
├── data.Rmd               # Data sources & wrangling pipeline
├── report.Rmd             # Full academic report
├── _site.yml              # Website configuration
├── styles.css             # Custom CSS styling
├── images/                # All figures and images
├── site_libs/             # R Markdown site libraries
└── data/
    ├── derived/           # Analysis-ready panel data (parquet)
    ├── mta_ridership_full/# Raw ridership CSVs
    ├── weather/           # NOAA weather data
    ├── events/            # NYC permitted events
    ├── stations/          # Station complex coordinates
    ├── documentation/     # Data documentation
    └── *.R                # Download scripts
```

## Data Sources

- **MTA Subway Ridership:** Hourly ridership by station complex via [NY Open Data](https://data.ny.gov/)
- **Weather:** Daily observations from Central Park via [NOAA GHCN-Daily](https://www.ncei.noaa.gov/cdo-web/)
- **Events:** NYC Permitted Event Information via [NYC Open Data](https://data.cityofnewyork.us/)
- **Stations:** Station complex coordinates extracted from MTA data

## Reproducing the Analysis

1. Clone the repository
2. Run the download scripts in `data/` to fetch raw data:
   ```r
   source("data/download_full_ridership_monthly.R")
   source("data/download_historical_events_monthly.R")
   source("data/download_noaa_weather.R")
   ```
3. Build the website:
   ```r
   rmarkdown::render_site()
   ```

## Contact

For questions or contributions, please contact any team member listed above.
