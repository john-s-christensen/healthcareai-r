% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/evaluate.R
\name{evaluate}
\alias{evaluate}
\alias{evaluate.predicted_df}
\alias{evaluate.model_list}
\title{Get model performance metrics}
\usage{
evaluate(x, ...)

\method{evaluate}{predicted_df}(x, na.rm = FALSE, ...)

\method{evaluate}{model_list}(x, all_models = FALSE, ...)
}
\arguments{
\item{x}{Object to be evaluted}

\item{...}{Not used}

\item{na.rm}{Logical. If FALSE (default) performance metrics will be NA if
any rows are missing an outcome value. If TRUE, performance will be
evaluted on the rows that have an outcome value. Only used when evaluating
a prediction data frame.}

\item{all_models}{Logical. If FALSE (default), a numeric vector giving
performance metrics for the best-performing model is returned. If TRUE,
a data frame with performance metrics for all trained models is returned.
Only used when evaluating a model_list.}
}
\value{
Either a numeric vector or a data frame depending on the value of
  all_models
}
\description{
Get model performance metrics
}
\details{
This function gets model performance from a model_list object that
  comes from \code{\link{machine_learn}}, \code{\link{tune_models}},
  \code{\link{flash_models}}, or a data frame of predictions from
  \code{\link{predict.model_list}}. For the latter, the data passed to
  \code{predict.model_list} must contain observed outcomes. If you have
  predictions and outcomes in a different format, see
  \code{\link{evaluate_classification}} or \code{\link{evaluate_regression}}
  instead.

  You may notice that \code{evaluate(models)} and
  \code{evaluate(predict(models))} return slightly different performance
  metrics, even though they are being calculated on the same (out-of-fold)
  predictions. This is because metrics in training (returned from
  \code{evaluate(models)}) are calculated within each cross-validation fold
  and then averaged, while metrics calculated on the prediction data frame
  (\code{evaluate(predict(models))}) are calculated once on all observations.
}
\examples{
models <- machine_learn(pima_diabetes[1:40, ],
                       patient_id,
                       outcome = diabetes,
                       models = c("XGB", "RF"),
                       tune = FALSE,
                       n_folds = 3)

# By default, evaluate returns performance of only the best model
evaluate(models)

# Set all_models = TRUE to see the performance of all trained models
evaluate(models, all_models = TRUE)

# Can also get performance on a test dataset
predictions <- predict(models, newdata = pima_diabetes[41:50, ])
evaluate(predictions)
}
