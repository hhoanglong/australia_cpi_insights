# Australia CPI Insights

Australia CPI Insights is an interactive R Shiny dashboard for exploring year-on-year changes in the Australian Consumer Price Index. It compares Australia-wide CPI with capital-city CPI series from April 2025 to March 2026.

## Live application

[Open Australia CPI Insights](https://r5gs7a-long-ngo.shinyapps.io/Australia-CPI-Insights/)

## Features

- Compare capital-city CPI changes for a selected month.
- View the Australia-wide CPI value as a reference alongside capital-city results.
- Move through the reporting period with an interactive month slider and animation control.
- Review summary indicators for Australia and the highest- and lowest-average capital cities.
- Display a twelve-month trend for Australia, one capital city, or two selected regions.
- Explore interactive Plotly charts with responsive dashboard layouts.

## Screenshots

Screenshots of the two dashboard views will be added here.

<!--
Create a screenshots directory, add the image files, and then remove this comment wrapper.

### Capital Cities vs Australia

![Capital Cities vs Australia dashboard](screenshots/capital-cities-vs-australia.png)

### Australia and Capital Cities Trends

![Australia and Capital Cities Trends dashboard](screenshots/australia-capital-cities-trends.png)
-->

## Technology

- R
- Shiny
- Plotly and ggplot2
- dplyr and tidyr
- readxl
- stringr

## Project structure

```text
australia-cpi-insights/
|-- ui.R
|-- server.R
|-- 640101.xlsx
|-- README.md
|-- .gitignore
```

The application currently expects `640101.xlsx` to be stored in the same directory as `ui.R` and `server.R`.

## Run locally

1. Install R and RStudio.
2. Clone or download this repository.
3. Open the project directory in RStudio.
4. Install the required packages:

```r
install.packages(c(
  "shiny",
  "readxl",
  "dplyr",
  "tidyr",
  "stringr",
  "ggplot2",
  "plotly"
))
```

5. Start the application:

```r
shiny::runApp()
```

## Data source

The dashboard uses the Consumer Price Index workbook published by the Australian Bureau of Statistics:

[Consumer Price Index, Australia](https://www.abs.gov.au/statistics/economy/price-indexes-and-inflation/consumer-price-index-australia/latest-release#data-downloads)

The application reads the official year-on-year percentage-change series supplied in the workbook rather than recalculating those values from index numbers.

## Repository notes

- Rename the final source files to exactly `ui.R` and `server.R` before running or deploying the application.
- Do not commit `.Renviron`, deployment tokens, API credentials, or other private configuration.
- The `rsconnect/` directory is not required for someone to run the application locally.
- Confirm that public sharing is permitted before publishing coursework or previously submitted assessment material.

## License

No license has been selected yet. Add a license only after confirming that the code and included data can be publicly redistributed.
