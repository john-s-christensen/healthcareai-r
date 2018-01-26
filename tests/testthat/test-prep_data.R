context("Testing prep_data")

# Setup ------------------------------------------------------------------------
# set seed for reproducibility
set.seed(7)
# build data set to predict whether or not animal_id is a is_ween
n <- 300
df <- data.frame(
  song_id = 1:n,
  length = rnorm(n, mean = 4, sd = 1),
  weirdness = rnorm(n, mean = 4, sd = 2),
  genre = sample(c("Rock", "Jazz", "Country"), size = n, replace = T),
  reaction = sample(c("Love", "Huh", "Dislike", "Mixed"),
                    size = n, replace = T),
  guitar_flag = sample(c(0, 1), size = n, replace = T),
  drum_flag = sample(c(0, 1, NA), size = n, replace = T,
                     prob = c(0.45, 0.45, 0.1)),
  date_col = lubridate::ymd("2002-03-04") + lubridate::days(sample(1000, n)),
  posixct_col = lubridate::ymd("2004-03-04") + lubridate::days(sample(1000, n)),
  col_DTS = lubridate::ymd("2006-03-04") + lubridate::days(sample(1000, n)),
  missing82 = sample(1:10, n, replace = TRUE),
  missing64 = sample(100:300, n, replace = TRUE),
  state = sample(c("NY", "MA", "CT", "CA", "VT", "NH"), size = n, replace = T,
                 prob = c(0.18, 0.1, 0.1, 0.6, 0.01, 0.01)),
  a_nzv_col = sample(c("man", "boognish"),
                     size = n, replace = T, prob = c(0.999, 0.001))
)

# give is_ween likeliness score
df["is_ween"] <- df["length"] - 1 * df["weirdness"] + 2
df$is_ween[df["genre"] == "Rock"]  <-
  df$is_ween[df["genre"] == "Rock"] + 2
df$is_ween[df["genre"] == "Jazz"]  <-
  df$is_ween[df["genre"] == "Jazz"] - 1
df$is_ween[df["genre"] == "Country"]  <-
  df$is_ween[df["genre"] == "Country"] - 1
df$is_ween[df["reaction"] == "Huh"] <-
  df$is_ween[df["reaction"] == "Huh"] + 1
df$is_ween[df["reaction"] == "Love"] <-
  df$is_ween[df["reaction"] == "Love"] + 2
df$is_ween[df["reaction"] == "Mixed"] <-
  df$is_ween[df["reaction"] == "Mixed"] - 1
df$is_ween[df["reaction"] == "Dislike"] <-
  df$is_ween[df["reaction"] == "Dislike"] - 4


# Add noise
df$is_ween <- df$is_ween + rnorm(n, mean = 0, sd = 1.25)
df$is_ween <- ifelse(df$is_ween > 0, "Y", "N")

# Add missing data
df$reaction[sample(1:n, 32, replace = FALSE)] <- NA
df$length[sample(1:n, 51, replace = FALSE)] <- NA
df$genre[sample(1:n, 125, replace = FALSE)] <- NA
df$weirdness[sample(1:n, 9, replace = FALSE)] <- NA

train_index <- caret::createDataPartition(
  df$is_ween,
  p = 0.8,
  times = 1,
  list = TRUE)

d_train <- df[train_index$Resample1, ]
d_test <- df[-train_index$Resample1, ]

d_train$length[1] <- d_test$length[1] <- NA
d_train$reaction[2] <- d_test$reaction[2] <- NA
d_train$weirdness[3] <-  d_test$weirdness[3] <- NA
d_train$genre[3] <- d_test$genre[3] <- NA


# Tests ------------------------------------------------------------------------
test_that("Bad data throws an error", {
  expect_error(prep_data(),
               regexp = "\"d\" must be a tibble")
  expect_error(prep_data(d = "yeah hi!"),
               regexp = "\"d\" must be a tibble")
})

test_that("Bad ignored columns throws an error", {
  expect_error(prep_data(d = d_train, cowbell),
               regexp = "not found in d")
  expect_error(prep_data(d = d_train, cowbell, spoons),
               regexp = "not found in d")
})

test_that("0/1 columns are found and converted with defaults", {
  capture_output(
    d_clean <- prep_data(d = d_train, is_ween, song_id)
  )
  expect_true(is.factor(d_clean$guitar_flag))
  expect_true(is.factor(d_clean$drum_flag))
  expect_true(all(c("N", "Y") %in% levels(d_clean$guitar_flag)))
  expect_true(all(c("N", "Y") %in% levels(d_clean$drum_flag)))
  expect_true(all.equal(which(d_clean$drum_flag == "Y"),
                        which(d_train$drum_flag == 1)))
  expect_true(all.equal(which(d_clean$drum_flag == "N"),
                        which(d_train$drum_flag == 0)))

})

test_that("date columns are found and converted with defaults", {
  capture_output(
    d_clean <- prep_data(d = d_train, is_ween, song_id)
  )
  expect_true(is.factor(d_clean$date_col_dow))
  expect_true(is.factor(d_clean$posixct_col_month))
  expect_true(is.numeric(d_clean$col_DTS_year))
  expect_true(all(c("Jan", "Mar") %in% d_clean$date_col_month))
  expect_true(all(2004:2006 %in% d_clean$posixct_col_year))
  expect_true(all(c("Sun", "Mon", "Tue") %in% d_clean$col_DTS_dow))
})

test_that("convert_dates works when non default", {
  capture_output(
    dd <- prep_data(d_train, convert_dates = "quarter")
  )
  expect_true("date_col_quarter" %in% names(dd))
  expect_false("date_col_dow" %in% names(dd))

  capture_output(
    dd <- prep_data(d_train, convert_dates = c("doy", "quarter"))
  )
  expect_true(all(c("date_col_doy", "date_col_quarter") %in% names(dd)))
})

test_that("convert_dates removes date columns when false", {
  capture_output(
    dd <- prep_data(d_train, convert_dates = FALSE)
  )
  expect_true(!all(c("date_col", "posixct_col", "col_DTS") %in% names(dd)))
})

test_that("prep_data works with defaults", {
  capture_output(
    d_clean <- prep_data(d = d_train, is_ween, song_id)
  )
  expect_equal(unique(d_clean$weirdness[is.na(d_train$weirdness)]),
               mean(d_train$weirdness, na.rm = TRUE))
  expect_true(all.equal(droplevels(d_clean$genre[!is.na(d_train$genre)]),
                        d_train$genre[!is.na(d_train$genre)]))
  expect_true(all(d_clean$genre[is.na(d_train$genre)] == "hcai_missing"))
})

test_that("prep_data applies recipe from training on test data", {
  capture_output(
    d_clean <- prep_data(d = d_train, is_ween, song_id)
  )
  capture_output(
    d_clean_test <- prep_data(d_test, is_ween, song_id,
                            rec_obj = attr(d_clean, "rec_obj"))
  )
  capture_output(
    d_clean_test2 <- prep_data(d_test, is_ween, song_id, rec_obj = d_clean)
  )
  expect_equal(d_clean_test, d_clean_test2)
  expect_equal(unique(d_clean_test$weirdness[is.na(d_test$weirdness)]),
               mean(d_train$weirdness, na.rm = TRUE))
  expect_true(all(d_clean_test$genre[is.na(d_test$genre)] == "hcai_missing"))
})

test_that("prep_data works when certain column types are missing", {
  d2 <- d_train %>%
    dplyr::select(-dplyr::one_of(c("a_nzv_col", "date_col", "posixct_col",
                                   "col_DTS", "drum_flag", "guitar_flag")))
  capture_output(
    d_clean <- prep_data(d = d2, is_ween, song_id)
  )
  expect_equal(unique(d_clean$weirdness[is.na(d2$weirdness)]),
               mean(d2$weirdness, na.rm = TRUE))
  expect_true(all.equal(droplevels(d_clean$genre[!is.na(d2$genre)]),
                        d2$genre[!is.na(d2$genre)]))
  expect_true(all(d_clean$genre[is.na(d2$genre)] == "hcai_missing"))
})

test_that("near zero variance columns are removed", {
  capture_output(
    d_clean <- prep_data(d = d_train,
                         is_ween,
                         song_id)
  )
  expect_true(is.null(d_clean$a_nzv_col))
})

test_that("impute works with params", {
  capture_output(
    d_clean <- prep_data(d_train, is_ween, song_id,
                       impute = list(numeric_method = "knnimpute",
                                     nominal_method = "bagimpute",
                                     numeric_params = list(knn_K = 5),
                                     nominal_params = NULL))
  )
  expect_equal(d_clean$weirdness[3], 5.35, tol = .01)
  expect_equal(as.character(d_clean$genre[2]), "Jazz")
  expect_equal(as.character(d_clean$reaction[4]), "Dislike")
})

test_that("impute works with partial/extra params", {
  capture_output(
    d_clean <- prep_data(d = d_train,
                         is_ween,
                         song_id,
                         impute = list(numeric_method = "bagimpute"))
  )
  m <- missingness(d_clean)
  expect_true(all(m$percent_missing == 0))

  expect_warning(capture_output(
    d_clean <- prep_data(d = d_train,
                         is_ween,
                         song_id,
                         impute = list(numeric_method = "knnimpute",
                                       numeric_params = list(knn_K = 5),
                                       the_best_params = "Moi!"))),
    regexp = "the_best_params")
})


test_that("rare factors go to other", {
  capture_output(
    d_clean <- prep_data(d = d_train,
                         is_ween,
                         song_id)
  )
  exp <- c("CA", "CT", "MA", "NY", "other")
  expect_equal(levels(d_clean$state), exp)
  exp <- c("Dislike", "Huh", "Love", "Mixed", "hcai_missing")
  expect_equal(levels(d_clean$reaction), exp)
})

test_that("rare factors go to other when a threshold is specified", {
  capture_output(
    d_clean <- prep_data(d = d_train,
                       is_ween,
                       song_id,
                       collapse_rare_factors = 0.15)
  )
  exp <- c("CA", "NY", "other")
  expect_equal(levels(d_clean$state), exp)
})

test_that("centering and scaling work", {
  capture_output(
    d_clean <- prep_data(d = d_train,
                       is_ween,
                       song_id,
                       center = TRUE,
                       scale = TRUE)
  )
  expect_equal(mean(d_clean$length), 0, tol = .01)
  expect_equal(mean(d_clean$weirdness), 0, tol = .01)
  expect_equal(sd(d_clean$length), 1, tol = .01)
  expect_equal(sd(d_clean$weirdness), 1, tol = .01)
})

test_that("dummy columns are created as expected", {
  capture_output(
    d_clean <- prep_data(d = d_train,
                       is_ween,
                       song_id,
                       convert_dates = FALSE,
                       dummies = TRUE)
  )
  exp <- c("genre_Jazz", "genre_Rock", "genre_hcai_missing")
  n <- names(dplyr::select(d_clean, starts_with("genre")))
  expect_true(all(n == exp))

  exp <- c("guitar_flag_N", "guitar_flag_other")
  n <- names(dplyr::select(d_clean, starts_with("guitar")))
  expect_true(all(n == exp))

  exp <- c("reaction_Huh", "reaction_Love", "reaction_Mixed",
           "reaction_hcai_missing" )
  n <- names(dplyr::select(d_clean, starts_with("reaction")))
  expect_true(all(n == exp))
})

test_that("Output of impute is same for tibble vs data frame", {
  expect_equal(
    capture_output(prep_data(d_train)),
    capture_output(prep_data(tibble::as_tibble(d_train)))
  )
})

test_that("rec_obj attr is a recipe class object", {
  capture_output(dd <- prep_data(d_train))
  expect_true("rec_obj" %in% names(attributes(dd)))
  expect_s3_class(attr(dd, "rec_obj"), "recipe")
})

test_that("prep_summary attr is contained within prepped data", {
  capture_output(dd <- prep_data(d_train))
  expect_true("prep_summary" %in% names(attributes(dd)))
})

test_that("warning is given when ignored columns have missingness", {
  expect_warning(capture_output(
    prep_data(d_train, reaction, length)
  ),
  regexp = "reaction, length")
})

test_that("print method works as expected", {
  msg <- capture_output(
    capture_messages(
      dd <- prep_data(d = d_train,
                    song_id,
                    is_ween,
                    verbose = TRUE)
    )
  )
  expect_true(grepl("step 7 other training", msg))
  expect_true(grepl("genre            42.3", msg))
  expect_true(grepl("Collapsing factor levels for genre, reaction", msg))
  expect_true(grepl("is_ween nominal   ignored original", msg))
  expect_true(grepl("col_DTS_year numeric predictor  derived", msg))

  out <- capture_output(capture_messages(print(dd)))
  expect_true(grepl("genre            42.3", out))
  expect_true(grepl("Collapsing factor levels for genre, reaction", out))
  expect_true(grepl("is_ween nominal   ignored original", out))
  expect_true(grepl("col_DTS_year numeric predictor  derived", out))
})