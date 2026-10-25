# server.R
# Shiny server logic for the Australia CPI year-on-year change app.
# Place this file in the same folder as ui.R and 640101.xlsx.

library(shiny)
library(readxl)
library(dplyr)
library(tidyr)
library(stringr)
library(ggplot2)
library(plotly)

# -----------------------------------------------------------------------------
# 1. Locate the CPI workbook
# -----------------------------------------------------------------------------
# The app expects the ABS Excel file to sit in the same folder as ui.R/server.R.
# When publishing to shinyapps.io, include 640101.xlsx in the app folder before
# deploying. Shiny will then upload the data file with the app.
DATA_FILE <- "640101.xlsx"

# Chart colours used in the Capital Cities vs Australia bar chart.
# The Australia reference line uses a darker indigo that matches the
# purple-blue bar fill while still standing out clearly.
BAR_FILL_COLOUR <- "#9B8AFB"
AUSTRALIA_REFERENCE_COLOUR <- "#4F46E5"
AUSTRALIA_REFERENCE_LABEL_FILL <- "#EEF2FF"
TREND_LINE_COLOURS <- c(BAR_FILL_COLOUR, "#E58A00")

# Capital-city series that should appear as bars in the Capital Cities vs Australia view.
# Australia is deliberately NOT included here because it is shown separately as
# a national reference line on the horizontal bar chart.
CAPITAL_CITY_REGIONS <- c(
  "Sydney",
  "Melbourne",
  "Brisbane",
  "Adelaide",
  "Perth",
  "Hobart",
  "Darwin",
  "Canberra"
)

# -----------------------------------------------------------------------------
# 2. Helper functions
# -----------------------------------------------------------------------------

# Convert Excel serial date numbers into real R Date values.
# ABS spreadsheets often store dates as serial numbers such as 45748.
# In Excel, 45748 is 2025-04-01 when using origin "1899-12-30".
excel_serial_to_date <- function(x) {
  numeric_x <- suppressWarnings(as.numeric(x))
  as.Date(numeric_x, origin = "1899-12-30")
}

# Extract the region name from a long ABS series title.
# Example input:
# "Percentage Change from Corresponding Month of Previous Year ;  All groups CPI ;  Sydney ;"
# Example output:
# "Sydney"
extract_region_name <- function(series_title) {
  pieces <- str_split(series_title, ";", simplify = TRUE)
  region <- str_trim(pieces[, 3])
  region
}

# Read and clean the ABS CPI workbook.
# Important design choice:
# This app uses the year-on-year percentage change columns already provided by
# the workbook. We do NOT recalculate YoY from index numbers because the provided
# columns are the official prepared values and avoid rounding differences.
clean_cpi_yoy_data <- function(path = DATA_FILE) {
  if (!file.exists(path)) {
    stop(
      paste0(
        "Cannot find '", path, "'. Put 640101.xlsx in the same folder as ui.R and server.R."
      ),
      call. = FALSE
    )
  }
  
  # Read the Data1 sheet without treating the first row as normal column names.
  # The first 10 rows contain metadata such as Unit, Frequency, Series ID, etc.
  raw <- read_excel(
    path = path,
    sheet = "Data1",
    col_names = FALSE,
    .name_repair = "minimal"
  )
  
  # Row 1 contains the long ABS series titles. These titles tell us whether a
  # column is an index number, year-on-year percentage change, or previous-period
  # percentage change.
  series_titles <- as.character(unlist(raw[1, ], use.names = FALSE))
  
  # Select only the columns that already contain year-on-year percentage changes.
  # These are labelled "Percentage Change from Corresponding Month of Previous Year".
  yoy_cols <- which(str_detect(
    series_titles,
    regex("Percentage Change from Corresponding Month of Previous Year", ignore_case = TRUE)
  ))
  
  if (length(yoy_cols) == 0) {
    stop("No year-on-year CPI percentage-change columns were found in Data1.", call. = FALSE)
  }
  
  # Extract friendly region names from the ABS series titles.
  # For this workbook, the regions are Australia plus capital cities.
  region_names <- extract_region_name(series_titles[yoy_cols])
  
  # The first column contains Excel serial dates in the actual data rows.
  # Metadata rows have text in the first column, so as.numeric() turns them into NA.
  date_serials <- suppressWarnings(as.numeric(raw[[1]]))
  
  # Actual monthly observations begin after the metadata section. The condition
  # seq_along(date_serials) > 10 avoids accidentally picking metadata rows.
  data_row_numbers <- which(!is.na(date_serials) & seq_along(date_serials) > 10)
  
  if (length(data_row_numbers) == 0) {
    stop("No monthly CPI observation rows were found in Data1.", call. = FALSE)
  }
  
  # Keep only the observation rows and the YoY percentage-change columns.
  data_start <- min(data_row_numbers)
  data_end <- max(data_row_numbers)
  
  yoy_wide <- raw[data_start:data_end, c(1, yoy_cols)]
  names(yoy_wide) <- c("excel_date", region_names)
  
  # Convert the wide ABS spreadsheet layout into a tidy format:
  # one row = one month + one region + one YoY percentage value.
  yoy_long <- yoy_wide %>%
    mutate(month = excel_serial_to_date(excel_date)) %>%
    select(month, all_of(region_names)) %>%
    pivot_longer(
      cols = -month,
      names_to = "region",
      values_to = "yoy_change"
    ) %>%
    mutate(
      yoy_change = suppressWarnings(as.numeric(yoy_change)),
      month_label = format(month, "%b %Y")
    ) %>%
    filter(!is.na(month), !is.na(yoy_change)) %>%
    # Your assignment scope is Apr 2025 to Mar 2026. This matches the available
    # YoY range in the workbook.
    filter(month >= as.Date("2025-04-01"), month <= as.Date("2026-03-31")) %>%
    arrange(month, region)
  
  yoy_long
}

# Format a percentage value that is already stored as a percentage point number.
# Example: 3.8 becomes "3.8%", not "380%".
format_pct <- function(x) {
  ifelse(is.na(x), "N/A", paste0(format(round(x, 1), nsmall = 1), "%"))
}

# -----------------------------------------------------------------------------
# 3. Shiny server
# -----------------------------------------------------------------------------

server <- function(input, output, session) {
  # Load and clean the data once when the app starts.
  # This is efficient because the CPI workbook is small.
  cpi_yoy <- clean_cpi_yoy_data(DATA_FILE)
  
  # Keep only capital-city names that are actually present in the workbook.
  # This protects the app if the workbook structure changes slightly later.
  available_capital_regions <- CAPITAL_CITY_REGIONS[CAPITAL_CITY_REGIONS %in% unique(cpi_yoy$region)]
  
  # Prepare choices for the month slider.
  month_choices <- cpi_yoy %>%
    distinct(month, month_label) %>%
    arrange(month)
  
  # Prepare choices for the Australia & Capital Cities Trends page checkboxes.
  # "All regions" is deliberately not included because it now has its own page.
  single_region_choices <- c("Australia", available_capital_regions)
  
  # Update the month slider after the data is loaded.
  # The slider uses month numbers 1 to 12 so the Play button moves cleanly
  # month-by-month instead of jumping by individual days.
  updateSliderInput(
    session,
    inputId = "selected_month",
    min = 1,
    max = nrow(month_choices),
    value = nrow(month_choices),
    step = 1
  )
  
  # Update the Australia & Capital Cities Trends page checkboxes after the data is loaded.
  updateCheckboxGroupInput(
    session,
    inputId = "selected_regions",
    choices = single_region_choices,
    selected = "Australia"
  )
  
  # Keep the second page comparison focused by allowing no more than two
  # selected regions at the same time. If all options are cleared, return to
  # the default Australia-only view.
  observeEvent(input$selected_regions, {
    selected_regions <- input$selected_regions
    
    if (is.null(selected_regions) || length(selected_regions) == 0) {
      updateCheckboxGroupInput(
        session,
        inputId = "selected_regions",
        selected = "Australia"
      )
    } else if (length(selected_regions) > 2) {
      updateCheckboxGroupInput(
        session,
        inputId = "selected_regions",
        selected = selected_regions[1:2]
      )
    }
  }, ignoreNULL = FALSE)
  
  # Convert the selected slider position into the matching Date.
  # Slider value 1 = Apr 2025, 2 = May 2025, ..., 12 = Mar 2026.
  selected_month <- reactive({
    req(input$selected_month)
    month_index <- as.integer(input$selected_month)
    month_index <- max(1, min(month_index, nrow(month_choices)))
    month_choices$month[month_index]
  })
  
  # Data for the selected month across all regions, including Australia.
  # Do not remove Australia here because the app still needs it for the national
  # reference line on the Capital Cities vs Australia page.
  selected_month_data <- reactive({
    cpi_yoy %>%
      filter(month == selected_month()) %>%
      arrange(desc(yoy_change))
  })
  
  # Bar-chart data for Capital Cities vs Australia page.
  # This excludes Australia from the bars and keeps only the capital cities.
  selected_month_bar_data <- reactive({
    selected_month_data() %>%
      filter(region %in% available_capital_regions) %>%
      arrange(desc(yoy_change))
  })
  
  # Australia value for the selected month.
  # This is used as the reference line in Capital Cities vs Australia page.
  selected_month_australia_value <- reactive({
    australia_value <- selected_month_data() %>%
      filter(region == "Australia") %>%
      pull(yoy_change)
    
    if (length(australia_value) == 0) {
      return(NA_real_)
    }
    
    australia_value[1]
  })
  
  # Average YoY CPI values across the full recorded assignment period.
  # This is used only for the KPI cards in the Capital Cities vs Australia page.
  # The selected-month chart and Australia reference line still use the selected month.
  all_regions_period_summary <- reactive({
    period_df <- cpi_yoy %>%
      filter(month >= as.Date("2025-04-01"), month <= as.Date("2026-03-31"))
    
    australia_average <- period_df %>%
      filter(region == "Australia") %>%
      summarise(avg_yoy_change = mean(yoy_change, na.rm = TRUE), .groups = "drop") %>%
      pull(avg_yoy_change)
    
    capital_city_averages <- period_df %>%
      filter(region %in% available_capital_regions) %>%
      group_by(region) %>%
      summarise(avg_yoy_change = mean(yoy_change, na.rm = TRUE), .groups = "drop")
    
    list(
      australia_average = ifelse(length(australia_average) == 0, NA_real_, australia_average[1]),
      highest_city = capital_city_averages %>% slice_max(avg_yoy_change, n = 1, with_ties = FALSE),
      lowest_city = capital_city_averages %>% slice_min(avg_yoy_change, n = 1, with_ties = FALSE)
    )
  })
  
  # Selected regions for the Australia & Capital Cities Trends page.
  # The default is Australia, and the selection is capped at two regions.
  selected_trend_regions <- reactive({
    selected_regions <- input$selected_regions
    
    if (is.null(selected_regions) || length(selected_regions) == 0) {
      return("Australia")
    }
    
    selected_regions <- selected_regions[selected_regions %in% single_region_choices]
    
    if (length(selected_regions) == 0) {
      return("Australia")
    }
    
    selected_regions[seq_len(min(2, length(selected_regions)))]
  })
  
  # Data for the selected region or two selected regions across all months.
  # This is not filtered by selected_month because the Australia & Capital Cities Trends page should
  # always show the full Apr 2025 to Mar 2026 time-series trend.
  selected_regions_data <- reactive({
    selected_regions <- selected_trend_regions()
    
    cpi_yoy %>%
      filter(region %in% selected_regions) %>%
      mutate(region = factor(region, levels = selected_regions)) %>%
      arrange(region, month)
  })
  
  # ---------------------------------------------------------------------------
  # Capital Cities vs Australia page: KPI cards
  # ---------------------------------------------------------------------------
  output$all_regions_kpi_cards <- renderUI({
    req(input$selected_month)
    
    month_label <- format(selected_month(), "%b %Y")
    
    # In Capital Cities vs Australia page, the chart still follows the selected month.
    # These KPI cards deliberately summarise the full Apr 2025 to Mar 2026 period.
    period_summary <- all_regions_period_summary()
    highest_row <- period_summary$highest_city
    lowest_row <- period_summary$lowest_city
    
    div(
      class = "kpi-grid",
      div(class = "kpi-card", div(class = "kpi-label", "Selected month"), div(class = "kpi-value", month_label)),
      div(class = "kpi-card", div(class = "kpi-label", "AUS RECORDED PERIOD AVG YOY CPI CHANGE"), div(class = "kpi-value kpi-period-value", format_pct(period_summary$australia_average))),
      div(class = "kpi-card", div(class = "kpi-label", paste0("Highest Avg YoY CPI Change - ", highest_row$region)), div(class = "kpi-value kpi-period-value", format_pct(highest_row$avg_yoy_change))),
      div(class = "kpi-card", div(class = "kpi-label", paste0("Lowest Avg YoY CPI Change - ", lowest_row$region)), div(class = "kpi-value kpi-period-value", format_pct(lowest_row$avg_yoy_change)))
    )
  })
  
  # ---------------------------------------------------------------------------
  # Capital Cities vs Australia page: fixed chart title
  # ---------------------------------------------------------------------------
  output$all_regions_plot_title <- renderText({
    "Capital Cities YoY CPI Change vs Australia Average"
  })
  
  # ---------------------------------------------------------------------------
  # Capital Cities vs Australia page: horizontal bar chart
  # ---------------------------------------------------------------------------
  output$all_regions_yoy_plot <- renderPlotly({
    req(input$selected_month)
    
    # Cross-region comparison for the selected month.
    # The bars only show capital cities. Australia is extracted separately and
    # drawn as a reference line instead of being shown as a bar.
    plot_data <- selected_month_bar_data() %>%
      mutate(
        region_for_plot = reorder(region, yoy_change),
        label = format_pct(yoy_change),
        # Put value labels slightly beyond the end of each horizontal bar.
        # This keeps the labels readable without changing the bar values.
        label_position = yoy_change + 0.16
      )
    
    req(nrow(plot_data) > 0)
    
    australia_value <- selected_month_australia_value()
    australia_label <- paste0("Australia Average: ", format_pct(australia_value))
    
    p <- ggplot(plot_data, aes(x = region_for_plot, y = yoy_change)) +
      geom_col(fill = BAR_FILL_COLOUR, width = 0.68)
    
    if (!is.na(australia_value)) {
      # Because coord_flip() is used later, geom_hline() becomes a vertical
      # reference line in the final horizontal bar chart. A solid indigo line
      # is used so it matches the purple-blue bar palette without looking harsh.
      # The text label is added later with Plotly annotations, because ggplot
      # labels near the plot edge can be clipped after ggplotly() conversion.
      p <- p +
        geom_hline(
          yintercept = australia_value,
          linetype = "solid",
          linewidth = 0.95,
          color = AUSTRALIA_REFERENCE_COLOUR
        )
    }
    
    p <- p +
      coord_flip() +
      labs(
        x = NULL,
        y = "Year-on-year change (%)",
        caption = "Source: ABS CPI workbook, Data1 sheet"
      ) +
      # Fix the YoY axis so the horizontal scale stays stable during month changes.
      # Because coord_flip() is used, this y-scale appears as the horizontal axis.
      scale_y_continuous(
        limits = c(0, 6),
        breaks = c(0, 2, 4, 6)
      ) +
      theme_minimal(base_size = 12) +
      theme(
        panel.grid.major.y = element_blank(),
        panel.grid.minor = element_blank(),
        plot.caption = element_text(color = "#64748b", size = 9),
        axis.text = element_text(color = "#334155"),
        axis.title.x = element_text(margin = margin(t = 8))
      ) +
      geom_text(
        aes(y = label_position, label = label),
        hjust = 0,
        size = 3.4,
        color = "#111827"
      )
    
    # Disable hover tooltips for every Plotly trace in the Capital Cities vs Australia chart,
    # including the geom_col() bars and the geom_text() value labels.
    plotly_chart <- ggplotly(p, tooltip = "none") %>%
      layout(margin = list(l = 82, r = 22, t = 44, b = 48)) %>%
      style(hoverinfo = "skip")
    
    if (!is.na(australia_value)) {
      plotly_chart <- plotly_chart %>%
        layout(
          annotations = list(
            list(
              x = australia_value,
              y = 1.04,
              xref = "x",
              yref = "paper",
              text = australia_label,
              showarrow = FALSE,
              xanchor = "center",
              yanchor = "bottom",
              font = list(
                color = AUSTRALIA_REFERENCE_COLOUR,
                size = 11
              ),
              bgcolor = AUSTRALIA_REFERENCE_LABEL_FILL,
              bordercolor = AUSTRALIA_REFERENCE_COLOUR,
              borderwidth = 1,
              borderpad = 3
            )
          )
        )
    }
    
    plotly_chart %>%
      config(displayModeBar = FALSE)
  })
  
  # ---------------------------------------------------------------------------
  # Australia & Capital Cities Trends page: dynamic chart title
  # ---------------------------------------------------------------------------
  output$single_region_plot_title <- renderText({
    selected_regions <- selected_trend_regions()
    region_title <- paste(selected_regions, collapse = " and ")
    paste("CPI YoY Change Over Time -", region_title)
  })
  
  # ---------------------------------------------------------------------------
  # Australia & Capital Cities Trends page: full time-series chart
  # ---------------------------------------------------------------------------
  output$single_region_yoy_plot <- renderPlotly({
    selected_regions <- selected_trend_regions()
    
    # Time-series view for one or two selected regions.
    # This chart is not filtered by month and does not use the month slider.
    plot_data <- selected_regions_data() %>%
      mutate(
        label = format_pct(yoy_change),
        # Place value labels using a real y-position rather than only vjust.
        # This works more reliably after ggplotly() converts the ggplot.
        label_position = yoy_change + 0.24,
        tooltip = paste0(
          "Region: ", region,
          "<br>Month: ", format(month, "%b %Y"),
          "<br>YoY CPI change: ", format_pct(yoy_change)
        )
      )
    
    line_colours <- setNames(
      TREND_LINE_COLOURS[seq_along(selected_regions)],
      selected_regions
    )
    legend_position <- if (length(selected_regions) > 1) "top" else "none"
    
    p <- ggplot(
      plot_data,
      aes(x = month, y = yoy_change, color = region, text = tooltip, group = region)
    ) +
      geom_line(linewidth = 1.15) +
      geom_point(size = 2.4) +
      scale_color_manual(values = line_colours, breaks = selected_regions, name = NULL) +
      labs(
        x = NULL,
        y = "Year-on-year change (%)",
        caption = "Source: ABS CPI workbook, Data1 sheet"
      ) +
      scale_x_date(date_breaks = "1 month", date_labels = "%b\n%Y") +
      theme_minimal(base_size = 12) +
      theme(
        legend.position = legend_position,
        legend.margin = margin(b = 0),
        legend.box.margin = margin(b = -6),
        panel.grid.minor = element_blank(),
        plot.caption = element_text(color = "#64748b", size = 9),
        axis.text = element_text(color = "#334155", size = 10),
        axis.title.y = element_text(margin = margin(r = 10))
      ) +
      geom_text(
        aes(y = label_position, label = label),
        vjust = 0,
        size = 3,
        color = "#111827",
        show.legend = FALSE
      )
    
    # Add headroom so the raised labels are not clipped at the top of the chart.
    p <- p + expand_limits(y = max(plot_data$label_position, na.rm = TRUE) + 0.12)
    
    ggplotly(p, tooltip = "text") %>%
      layout(
        margin = list(l = 64, r = 24, t = 12, b = 62),
        legend = list(orientation = "h", x = 0, y = 1.08)
      ) %>%
      config(displayModeBar = FALSE)
  })
  
}
