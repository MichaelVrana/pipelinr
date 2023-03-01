test_that("it finds unbound body args", {
    stage <- stage(stage_inputs(a = 1), body = function(a, b) list(a, b))

    unbound <- find_unbound_body_args(stage)

    expect_equal(unbound, c(b = "b"))
})

test_that("it finds no unbound body args", {
    stage <- stage(stage_inputs(a = 1, b = list()), body = function(a, b) list(a, b))

    unbound <- find_unbound_body_args(stage)
    expect_equal(unbound, character())
})

test_that("it finds no unbound body args", {
    stage <- stage(function() list(a, b))

    unbound <- find_unbound_body_args(stage)

    expect_equal(unbound, character())
})
