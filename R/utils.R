# =============================================================================
# Shared Utility Functions for World Happiness Analysis
# =============================================================================

library(mice)
library(dplyr)
library(tibble)
library(ggplot2)
library(Metrics)
library(gridExtra)

# -- Data Loading -------------------------------------------------------------

#' Load World Happiness Report train (2018) and test (2019) datasets
#'
#' @param data_dir Path to the directory containing the CSV files.
#' @return A named list with `train` and `test` data frames (row names = countries).
load_whr_data <- function(data_dir = here::here("data")) {
  train <- read.csv(
    file.path(data_dir, "WHR2018.csv"),
    header = TRUE, sep = ",", dec = ".", na.strings = "N/A", row.names = 2
  )
  test <- read.csv(
    file.path(data_dir, "WHR2019.csv"),
    header = TRUE, sep = ",", dec = ".", na.strings = "N/A", row.names = 2
  )
  list(train = train, test = test)
}

# -- Preprocessing ------------------------------------------------------------

#' Impute missing values using MICE (Multivariate Imputation by Chained Equations)
#'
#' @param df  Data frame with possible missing values.
#' @param m   Number of multiple imputations (default 5).
#' @param seed Seed for reproducibility (default 500).
#' @return Data frame with missing values imputed, row names preserved.
impute_missing <- function(df, m = 5, seed = 500) {
  original_rownames <- row.names(df)
  imputed <- mice::mice(df, m = m, seed = seed, printFlag = FALSE)
  result <- mice::complete(imputed, 1)
  row.names(result) <- original_rownames
  result
}

#' Countries identified as outliers in both univariate and multivariate analyses.
#' - Denmark, Singapore, Rwanda: extreme univariate outliers (Perceptions of corruption)
#' - United Arab Emirates: multivariate outlier (Mahalanobis distance)
OUTLIER_COUNTRIES <- c("Denmark", "Singapore", "Rwanda", "United Arab Emirates")

#' Remove identified outlier countries from the dataset
#'
#' @param df Data frame with country names as row names.
#' @param outliers Character vector of country names to remove.
#' @return Filtered data frame.
remove_outliers <- function(df, outliers = OUTLIER_COUNTRIES) {
  df[!row.names(df) %in% outliers, ]
}

#' Drop non-numeric columns for modeling
#'
#' @param df Data frame.
#' @param drop_rank   Remove Overall.rank column (default TRUE).
#' @param drop_region Remove Regional.Indicator column (default TRUE).
#' @return Data frame with specified columns removed.
prepare_numeric_data <- function(df, drop_rank = TRUE, drop_region = TRUE) {
  cols_to_drop <- c()
  if (drop_rank)   cols_to_drop <- c(cols_to_drop, "Overall.rank")
  if (drop_region) cols_to_drop <- c(cols_to_drop, "Regional.Indicator")
  df[, !names(df) %in% cols_to_drop, drop = FALSE]
}

# -- Outlier Detection --------------------------------------------------------

#' Detect univariate outliers using IQR method
#'
#' @param df   Data frame with country names as row names.
#' @param col  Column index to check.
#' @param mode Either "extreme" (3x IQR) or "mild" (1.5x IQR).
#' @return Data frame subset containing only outlier rows.
detect_univariate_outliers <- function(df, col, mode = c("extreme", "mild")) {
  mode <- match.arg(mode)
  multiplier <- if (mode == "extreme") 3 else 1.5
  lower <- as.numeric(quantile(df[, col], 0.25) - multiplier * IQR(df[, col]))
  upper <- as.numeric(quantile(df[, col], 0.75) + multiplier * IQR(df[, col]))
  df %>%
    rownames_to_column("country") %>%
    filter(df[, col] < lower | df[, col] > upper) %>%
    column_to_rownames("country")
}

# -- Visualization ------------------------------------------------------------

#' Consistent ggplot theme for the project
theme_whr <- function() {
  theme_bw() +
    theme(
      plot.title = element_text(hjust = 0.5, face = "bold", size = 14),
      panel.grid.major = element_blank(),
      panel.grid.minor = element_blank(),
      panel.background = element_blank(),
      axis.line = element_line(colour = "black"),
      legend.position = "bottom"
    )
}

#' Plot density histogram for a variable
#'
#' @param df        Data frame.
#' @param col       Column index.
#' @param title     Plot title.
#' @param y_label   Y-axis label (default "Density").
#' @return ggplot object.
plot_density <- function(df, col, title, y_label = "Density") {
  ggplot(df, aes(x = df[, col])) +
    geom_histogram(aes(y = after_stat(density)), bins = 25,
                   colour = "black", fill = "white") +
    geom_density(alpha = 0.2, fill = "#FF6666") +
    labs(x = "", y = y_label, title = title) +
    theme_whr() +
    scale_x_continuous(breaks = NULL)
}

#' Plot boxplot for a variable
#'
#' @param df  Data frame.
#' @param col Column index.
#' @return ggplot object.
plot_boxplot <- function(df, col) {
  ggplot(df, aes(x = factor(""), y = df[, col])) +
    geom_boxplot(fill = "azure3", outlier.color = "red", outlier.shape = 1) +
    labs(title = colnames(df)[col], x = "", y = "") +
    theme(legend.position = "none")
}

# -- Model Evaluation ---------------------------------------------------------

#' Evaluate a model's predictions against actual values
#'
#' @param actual    Numeric vector of actual values.
#' @param predicted Numeric vector of predicted values.
#' @param model_name Character string identifying the model.
#' @return A one-row data frame with Model, RMSE, MSE, and MAE.
evaluate_predictions <- function(actual, predicted, model_name) {
  data.frame(
    Model = model_name,
    RMSE  = Metrics::rmse(actual, predicted),
    MSE   = Metrics::mse(actual, predicted),
    MAE   = Metrics::mae(actual, predicted),
    stringsAsFactors = FALSE
  )
}

#' Plot actual vs. predicted values
#'
#' @param actual    Numeric vector of actual values.
#' @param predicted Numeric vector of predicted values.
#' @param title     Plot title.
#' @return ggplot object.
plot_predictions <- function(actual, predicted, title) {
  df_plot <- data.frame(Actual = actual, Predicted = as.vector(predicted))
  ggplot(df_plot, aes(Actual, Predicted)) +
    geom_point(size = 1.2, alpha = 0.7) +
    geom_abline(linetype = "dashed", color = "gray50") +
    labs(
      title = title,
      x = "Actual happiness score",
      y = "Predicted happiness score"
    ) +
    theme_whr()
}
