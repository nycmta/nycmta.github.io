# Download NYC GeoJSON boundary files for mapping
# Run this script once to download and cache the data locally

library(sf)

# Create geo directory if it doesn't exist
dir.create("data/geo", showWarnings = FALSE, recursive = TRUE)

# Download NYC Neighborhood Tabulation Areas (NTAs)
message("Downloading NYC Neighborhood Tabulation Areas...")
nta_url <- "https://data.cityofnewyork.us/api/geospatial/9nt8-h7nd?method=export&format=GeoJSON"
nyc_nta <- st_read(nta_url, quiet = TRUE)
st_write(nyc_nta, "data/geo/nyc_nta.geojson", delete_dsn = TRUE)
message("Saved: data/geo/nyc_nta.geojson")

# Download NYC Borough Boundaries (fallback)
message("Downloading NYC Borough Boundaries...")
borough_url <- "https://data.cityofnewyork.us/api/geospatial/7t3b-ywvw?method=export&format=GeoJSON"
tryCatch({
  nyc_boroughs <- st_read(borough_url, quiet = TRUE)
  st_write(nyc_boroughs, "data/geo/nyc_boroughs.geojson", delete_dsn = TRUE)
  message("Saved: data/geo/nyc_boroughs.geojson")
}, error = function(e) {
  message("Warning: Could not download borough boundaries. NTA file will be primary.")
})

message("Done! GeoJSON files saved to data/geo/")
