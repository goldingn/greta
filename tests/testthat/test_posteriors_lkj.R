Sys.setenv("RELEASE_CANDIDATE" = "false")

## This one is failing
test_that("samplers are unbiased for LKJ", {
  skip_if_not(check_tf_version())

  skip_if_not_release()

  x <- lkj_correlation(3, 2)[1, 2]
  iid <- function(n) {
    rlkjcorr(n, 3, 2)[, 1, 2]
  }

  lkj_checked <- check_samples(
    x = x,
    iid_function = iid,
    sampler = hmc(),
    one_by_one = TRUE
  )

  # do the plotting
  qqplot_checked_samples(lkj_checked)

  # do a formal hypothesis test
  stat <- ks_test_mcmc_vs_iid(lkj_checked)

  expect_gte(stat$p.value, 0.01)
})
