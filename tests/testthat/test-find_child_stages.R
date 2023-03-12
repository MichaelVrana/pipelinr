test_that("It finds child stages", {
    pipeline <- make_pipeline(
        a = stage(function() {}),
        b = stage(function(a) {}),
        c = stage(function(a, b) {}),
        d = stage(function(c) {}),
        e =stage(function() {})
    )

    expect_equal(find_child_stages(pipeline$stages, "a"), c("b", "c", "d"))
    expect_equal(find_child_stages(pipeline$stages, "b"), c("c", "d"))
    expect_equal(find_child_stages(pipeline$stages, "d"), character())
    expect_equal(find_child_stages(pipeline$stages, "e"), character())
})
