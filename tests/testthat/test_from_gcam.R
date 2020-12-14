
context("Example test")


test_that("gcam_modelx_sum result validation", {

  # check to make sure summing floats produces the expected output
  float_output <- gcam_modelx_sum(1.2, 1.3)
  expect_equal(float_output, 2.5)

  # check to make sure summing a float and an integer produces the expected output
  float_int_output <- gcam_modelx_sum(1.2, 1)
  expect_equal(float_int_output, 2.2)

  # check to make sure summing two integers produces the expected output
  int_output <- gcam_modelx_sum(1, 1)
  expect_equal(int_output, 2)

  # expect an error when characters are passed
  expect_error(gcam_modelx_sum('a', 'b'))

})
