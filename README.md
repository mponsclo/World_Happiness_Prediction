# World Happiness Report -- Predictive Analysis

<p align="center">
  <img src="data/WHR_10_logo_violet.png" alt="World Happiness Report" width="250">
</p>

> Can we predict a country's happiness score from economic and social indicators?
> This project applies multivariate statistics and machine learning to the [World Happiness Report](https://worldhappiness.report/), training on 2018 data (152 countries) and testing predictions against 2019.

## Key Results

| Model | Test RMSE (2019) |
|---|---|
| **Neural Network (nn1)** | **0.4818** |
| Random Forest | 0.4829 |
| Standard Linear Regression | 0.5231 |
| Lasso Regression | 0.5244 |
| Ridge Regression | 0.5267 |
| Neural Network (nn2) | 0.5437 |
| Polynomial Regression (deg 6) | 0.5406 |
| Decision Tree | 0.6484 |

**Key findings:**
- GDP per capita is the strongest single predictor of happiness (r = 0.80)
- Countries naturally cluster into 3 groups aligned with development levels
- Non-linear models (neural nets, random forests) outperform linear methods
- Generosity is not a significant predictor -- excluded by both stepwise selection and LASSO

## Approach

The analysis follows two incremental phases:

### Phase 1: Multivariate Analysis ([01_multivariate_analysis.Rmd](analysis/01_multivariate_analysis.Rmd))
Exploratory and unsupervised analysis to understand data structure:
- **Distribution assessment** -- Shapiro-Wilk tests, Q-Q plots, Mahalanobis distances
- **Dimensionality reduction** -- PCA reduces 7 variables to 2 components (73% variance)
- **Varimax rotation** -- Identifies 5 interpretable latent factors
- **Hierarchical clustering (HCPC)** -- Groups 152 countries into 5 clusters
- **Tree-based models** -- Decision trees and random forests with grid search tuning

### Phase 2: Machine Learning ([02_machine_learning.Rmd](analysis/02_machine_learning.Rmd))
Supervised prediction of the 2019 happiness scores:
- **Clustering** -- K-means and EM clustering confirm K=3 as optimal
- **Regression** -- Standard, Ridge (L2), Lasso (L1), and Polynomial regression
- **Tree ensembles** -- Decision trees with post-pruning, random forests
- **Neural networks** -- Single hidden layer with grid search over size and decay
- **Model comparison** -- All models evaluated on 2019 test set via RMSE

## Repository Structure

```
WHA/
├── README.md
├── data/
│   ├── WHR2018.csv              # Training data (156 countries, 7 features + region)
│   └── WHR2019.csv              # Test data (157 countries, 7 features)
├── R/
│   └── utils.R                  # Shared functions (data loading, preprocessing, evaluation)
├── analysis/
│   ├── 01_multivariate_analysis.Rmd
│   └── 02_machine_learning.Rmd
└── reports/
    ├── multivariate_analysis_report.pdf
    └── machine_learning_report.pdf
```

## How to Run

### Prerequisites

R (>= 4.0) and the following packages:

```r
install.packages(c(
  # Core
  "here", "mice", "dplyr", "tibble", "reshape2", "Metrics",
  # Visualization
  "ggplot2", "gplots", "gridExtra", "plotrix", "tableplot",
  "PerformanceAnalytics", "GGally",
  # Multivariate analysis
  "psych", "FactoMineR", "factoextra", "chemometrics", "pracma",
  # Clustering
  "cclust", "Rmixmod",
  # Modeling
  "glmnet", "MASS", "rpart", "rpart.plot", "randomForest",
  "caret", "nnet", "neuralnet", "NeuralNetTools",
  "boot", "rsample", "ROCR", "clusterGeneration"
))
```

### Render Reports

```r
rmarkdown::render("analysis/01_multivariate_analysis.Rmd")
rmarkdown::render("analysis/02_machine_learning.Rmd")
```

## Dataset

The [World Happiness Report](https://worldhappiness.report/) ranks 156 countries by perceived happiness.

| Variable | Description |
|---|---|
| **Score** (target) | Subjective well-being (0-10 scale) |
| GDP per capita | Log PPP-adjusted GDP per capita |
| Social support | "Can you count on others in trouble?" (0/1 avg) |
| Healthy life expectancy | WHO-based health/longevity metric |
| Freedom to make life choices | "Satisfied with your freedom?" (0/1 avg) |
| Generosity | Residual of charity donations regressed on GDP |
| Perceptions of corruption | "Is corruption widespread?" (0/1 avg) |
| Regional Indicator | 10-level categorical (supplementary) |

**Sources:**
[Kaggle](https://www.kaggle.com/unsdsn/world-happiness) |
[data.world](https://data.world/promptcloud/world-happiness-report-2019)

## Authors

Manuel Breve, Diego Quintana, Marcel Pons

*Developed as coursework for the Master in Innovation and Research in Informatics at UPC (Universitat Politecnica de Catalunya).*
