# ui.R
# Shiny user interface for the Australia CPI year-on-year change app.
# Place this file in the same folder as server.R and 640101.xlsx.

library(shiny)
library(plotly)

ui <- navbarPage(
  title = "Australia CPI Insights",
  id = "main_nav",
  selected = "all_regions_page",
  header = tags$head(
    tags$title("Australia CPI YoY Explorer"),
    tags$style(HTML("
      body {
        background: #f4f6f8;
        color: #1f2937;
        font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;
      }
      .navbar {
        border-radius: 0;
        margin-bottom: 0;
        min-height: 44px;
      }
      .navbar-brand,
      .navbar-nav > li > a {
        padding-top: 12px;
        padding-bottom: 12px;
      }
      .app-hero {
        background: linear-gradient(135deg, #1f2937 0%, #334155 55%, #475569 100%);
        color: white;
        padding: 28px 34px;
        border-radius: 18px;
        margin: 20px 0 22px 0;
        box-shadow: 0 14px 30px rgba(15, 23, 42, 0.18);
      }
      .app-hero h1 {
        margin-top: 0;
        font-weight: 750;
        letter-spacing: -0.03em;
      }
      .app-hero p {
        max-width: 940px;
        font-size: 16px;
        line-height: 1.55;
        color: #e5e7eb;
      }
      .control-card, .content-card, .kpi-card {
        background: #ffffff;
        border: 1px solid #e5e7eb;
        border-radius: 16px;
        box-shadow: 0 8px 24px rgba(15, 23, 42, 0.06);
      }
      .control-card {
        padding: 22px;
        margin-bottom: 18px;
      }
      .content-card {
        padding: 22px;
        margin-bottom: 18px;
      }
      .kpi-grid {
        display: grid;
        grid-template-columns: repeat(4, minmax(0, 1fr));
        gap: 14px;
        margin-bottom: 18px;
        align-items: stretch;
      }
      .kpi-card {
        padding: 14px 16px;
        min-height: 108px;
        display: flex;
        flex-direction: column;
        justify-content: center;
        overflow-wrap: break-word;
      }
      .kpi-label {
        font-size: 11px;
        line-height: 1.25;
        color: #64748b;
        text-transform: uppercase;
        letter-spacing: 0.035em;
        font-weight: 700;
      }
      .kpi-value {
        font-size: 28px;
        margin-top: 10px;
        font-weight: 800;
        color: #111827;
        letter-spacing: -0.02em;
      }
      .kpi-note {
        margin-top: 5px;
        font-size: 13px;
        color: #64748b;
      }
      .section-title {
        margin-top: 0;
        font-weight: 750;
        color: #111827;
      }
      .small-note {
        color: #64748b;
        font-size: 13px;
        line-height: 1.45;
      }
      .month-slider-card {
        margin-top: 24px;
        padding-top: 18px;
        border-top: 1px solid #e5e7eb;
      }
      .month-slider-card label {
        font-size: 18px;
      }
      .month-slider-card .irs-single,
      .month-slider-card .irs-min,
      .month-slider-card .irs-max,
      .month-slider-card .irs-from,
      .month-slider-card .irs-to,
      .month-slider-card .irs-grid-text {
        font-size: 18px !important;
        line-height: 1.25;
      }
      .month-slider-card .slider-animate-button,
      .month-slider-card .slider-animate-container .btn {
        font-size: 18px !important;
        padding: 6px 14px;
        line-height: 1.25;
      }
      .well {
        background: transparent;
        border: 0;
        box-shadow: none;
        padding: 0;
      }
      label {
        color: #334155;
        font-weight: 700;
      }
      .selectize-input, .form-control {
        border-radius: 10px;
        border-color: #cbd5e1;
      }
      .btn-default {
        border-radius: 10px;
      }
      .cpi-info-link {
        margin: 0 0 8px 0;
        font-size: 13px;
        line-height: 1.2;
      }
      .cpi-info-link a {
        display: inline-flex;
        align-items: center;
        gap: 6px;
        color: #2563eb;
        font-weight: 700;
        text-decoration: none;
      }
      .cpi-info-link a:hover,
      .cpi-info-link a:focus {
        color: #1d4ed8;
        text-decoration: underline;
      }
      .cpi-info-icon {
        display: inline-flex;
        align-items: center;
        justify-content: center;
        width: 18px;
        height: 18px;
        border-radius: 999px;
        background: #dbeafe;
        color: #2563eb;
        font-size: 12px;
        font-weight: 800;
      }
      .app-footer {
        margin-top: 8px;
        padding: 7px 10px;
        color: #64748b;
        font-size: 10.5px;
        line-height: 1.25;
        text-align: center;
        overflow-wrap: anywhere;
      }
      .app-footer a {
        color: #2563eb;
        text-decoration: none;
      }
      .app-footer a:hover,
      .app-footer a:focus {
        text-decoration: underline;
      }
      .kpi-period-value {
        color: #2563eb;
      }

      /* Compact layout for the homepage / Capital Cities vs Australia page only. */
      .all-regions-page .app-hero {
        padding: 9px 22px;
        margin: 8px 0 8px 0;
        border-radius: 14px;
        box-shadow: 0 8px 18px rgba(15, 23, 42, 0.14);
      }
      .all-regions-page .app-hero h1 {
        font-size: 24px;
        line-height: 1.15;
        margin: 0 0 3px 0;
      }
      .all-regions-page .app-hero h2 {
        font-size: 16px;
        line-height: 1.2;
        margin: 0;
        font-weight: 600;
      }
      .all-regions-page .kpi-grid {
        gap: 10px;
        margin-bottom: 8px;
      }
      .all-regions-page .kpi-card {
        padding: 8px 12px;
        min-height: 68px;
      }
      .all-regions-page .kpi-label {
        font-size: 9.5px;
        line-height: 1.15;
        letter-spacing: 0.018em;
      }
      .all-regions-page .kpi-value {
        font-size: 22px;
        line-height: 1.12;
        margin-top: 4px;
      }
      .all-regions-page .content-card {
        padding: 12px 16px 10px 16px;
        margin-bottom: 0;
      }
      .all-regions-page .section-title {
        font-size: 19px;
        line-height: 1.2;
        margin-bottom: 4px;
      }
      .all-regions-page .month-slider-card {
        margin-top: 6px;
        padding-top: 6px;
      }
      .all-regions-page .month-slider-card label {
        font-size: 16px;
      }
      .all-regions-page .month-slider-card .irs-single,
      .all-regions-page .month-slider-card .irs-min,
      .all-regions-page .month-slider-card .irs-max,
      .all-regions-page .month-slider-card .irs-from,
      .all-regions-page .month-slider-card .irs-to,
      .all-regions-page .month-slider-card .irs-grid-text {
        font-size: 16px !important;
        line-height: 1.2;
      }
      .all-regions-page .month-slider-card .slider-animate-button,
      .all-regions-page .month-slider-card .slider-animate-container .btn {
        font-size: 16px !important;
        padding: 4px 10px;
        line-height: 1.2;
      }
      .all-regions-page .irs {
        height: 44px;
      }
      .all-regions-page .irs-line,
      .all-regions-page .irs-bar {
        top: 26px;
      }
      .all-regions-page .irs-handle {
        top: 18px;
      }
      .all-regions-page .irs-single {
        top: -2px;
      }

      /* Compact layout for the Australia & Capital Cities Trends page. */
      .single-region-page .app-hero {
        padding: 9px 22px;
        margin: 8px 0 8px 0;
        border-radius: 14px;
        box-shadow: 0 8px 18px rgba(15, 23, 42, 0.14);
      }
      .single-region-page .app-hero h1 {
        font-size: 24px;
        line-height: 1.15;
        margin: 0 0 3px 0;
      }
      .single-region-page .app-hero h2 {
        font-size: 16px;
        line-height: 1.2;
        margin: 0;
        font-weight: 600;
      }
      .single-region-page .trend-layout {
        display: grid;
        grid-template-columns: 250px minmax(0, 1fr);
        gap: 12px;
        align-items: start;
      }
      .single-region-page .control-card {
        padding: 10px 14px;
        margin-bottom: 0;
      }
      .single-region-page .content-card {
        padding: 12px 16px 8px 16px;
        margin-bottom: 0;
      }
      .single-region-page .section-title {
        font-size: 19px;
        line-height: 1.2;
        margin-bottom: 4px;
      }
      .single-region-page h4 {
        font-size: 16px;
        line-height: 1.2;
        margin: 0 0 8px 0;
      }
      .single-region-page .options-title {
        font-size: 12px;
        line-height: 1.2;
        margin: 0 0 8px 0;
        letter-spacing: -0.02em;
        white-space: nowrap;
      }
      .single-region-page .form-group {
        margin-bottom: 8px;
      }
      .single-region-page .checkbox {
        margin-top: 2px;
        margin-bottom: 2px;
      }
      .single-region-page .checkbox label {
        font-size: 12.5px;
        line-height: 1.2;
        font-weight: 600;
      }
      .single-region-page hr {
        margin-top: 8px;
        margin-bottom: 8px;
      }
      .single-region-page .small-note {
        font-size: 12px;
        line-height: 1.3;
      }

      @media (max-width: 1000px) {
        .kpi-grid {
          grid-template-columns: repeat(2, minmax(0, 1fr));
        }
      }
      @media (max-width: 650px) {
        .kpi-grid {
          grid-template-columns: 1fr;
        }
        .app-hero {
          padding: 22px;
        }
        .all-regions-page .app-hero,
        .single-region-page .app-hero {
          padding: 14px 18px;
        }
        .single-region-page .trend-layout {
          grid-template-columns: 1fr;
        }
      }
    ")),
    tags$script(HTML("
      // Display month names above the selected_month slider handle.
      // The underlying slider values stay as 1-12, so the existing server logic
      // and Play/Pause animation continue to work unchanged.
      (function() {
        var monthLabels = [
          'Apr 2025', 'May 2025', 'Jun 2025', 'Jul 2025',
          'Aug 2025', 'Sep 2025', 'Oct 2025', 'Nov 2025',
          'Dec 2025', 'Jan 2026', 'Feb 2026', 'Mar 2026'
        ];

        function applyMonthSliderLabels() {
          var slider = $('#selected_month').data('ionRangeSlider');
          if (!slider) {
            return false;
          }

          slider.update({
            grid: false,
            prettify_enabled: true,
            prettify: function(value) {
              var monthIndex = Math.round(Number(value)) - 1;
              return monthLabels[monthIndex] || value;
            }
          });

          return true;
        }

        var attempts = 0;
        var sliderDisplayTimer = setInterval(function() {
          attempts = attempts + 1;
          if (applyMonthSliderLabels() || attempts >= 50) {
            clearInterval(sliderDisplayTimer);
          }
        }, 100);

        $(document).on('shiny:inputchanged', function(event) {
          if (event.name === 'selected_month') {
            setTimeout(applyMonthSliderLabels, 0);
          }
        });
      })();
    "))
  ),
  
  tabPanel(
    title = "Capital Cities vs Australia",
    value = "all_regions_page",
    div(
      class = "container-fluid all-regions-page",
      div(
        class = "app-hero",
        h1("Australia CPI Year-On-Year Change Explorer"),
        h2("Recorded Period: Apr 2025 - Mar 2026")
      ),
      div(
        class = "cpi-info-link",
        tags$a(
          href = "https://www.abs.gov.au/articles/frequently-asked-questions-faqs-about-consumer-price-index",
          target = "_blank",
          rel = "noopener noreferrer",
          tags$span("What is CPI"),
          tags$span(class = "cpi-info-icon", "?")
        )
      ),
      uiOutput("all_regions_kpi_cards"),
      div(
        class = "content-card",
        h3(class = "section-title", textOutput("all_regions_plot_title")),
        plotlyOutput("all_regions_yoy_plot", height = "305px"),
        div(
          class = "month-slider-card",
          sliderInput(
            inputId = "selected_month",
            label = "Month to analyse",
            width = "100%",
            min = 1,
            max = 12,
            value = 12,
            step = 1,
            ticks = FALSE,
            animate = animationOptions(
              interval = 1000,
              loop = FALSE,
              playButton = "Play",
              pauseButton = "Pause"
            )
          )
        )
      ),
      div(
        class = "app-footer",
        "Data Source: Australian Bureau of Statistics. (2026). Consumer Price Index, Australia. Australian Bureau of Statistics. ",
        tags$a(
          href = "https://www.abs.gov.au/statistics/economy/price-indexes-and-inflation/consumer-price-index-australia/latest-release#data-downloads",
          target = "_blank",
          rel = "noopener noreferrer",
          "https://www.abs.gov.au/statistics/economy/price-indexes-and-inflation/consumer-price-index-australia/latest-release#data-downloads"
        )
      )
    )
  ),
  
  tabPanel(
    title = "Australia & Capital Cities Trends",
    value = "single_region_page",
    div(
      class = "container-fluid single-region-page",
      div(
        class = "app-hero",
        h1("Australia CPI Year-On-Year Change Explorer"),
        h2("Recorded Period: Apr 2025 - Mar 2026")
      ),
      div(
        class = "trend-layout",
        div(
          class = "control-card",
          h4(class = "options-title", "Australia-Wide and City-Specific Options"),
          checkboxGroupInput(
            inputId = "selected_regions",
            label = "Select up to 2",
            choices = character(0),
            selected = "Australia"
          ),
          hr(),
          div(
            class = "small-note",
            strong("Data note:"),
            tags$ul(
              tags$li("Choose one option to view one geographic area's CPI YoY trend."),
              tags$li("Choose up to 2 options to compare a capital city with the Australia-wide average, or to compare two capital cities.")
            )
          )
        ),
        div(
          class = "content-card",
          h3(class = "section-title", textOutput("single_region_plot_title")),
          plotlyOutput("single_region_yoy_plot", height = "360px")
        )
      ),
      div(
        class = "app-footer",
        "Data Source: Australian Bureau of Statistics. (2026). Consumer Price Index, Australia. Australian Bureau of Statistics. ",
        tags$a(
          href = "https://www.abs.gov.au/statistics/economy/price-indexes-and-inflation/consumer-price-index-australia/latest-release#data-downloads",
          target = "_blank",
          rel = "noopener noreferrer",
          "https://www.abs.gov.au/statistics/economy/price-indexes-and-inflation/consumer-price-index-australia/latest-release#data-downloads"
        )
      )
    )
  )
)
