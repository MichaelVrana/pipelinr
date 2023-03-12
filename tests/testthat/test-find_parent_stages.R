test_that("It finds parent stages", {
    pipeline <- make_pipeline(
        a = stage(function() {}),
        b = stage(function(a) {}),
        c = stage(function(a, b) {}),
        d = stage(function(c) {}),
        e = stage(function() {})
    )

    expect_equal(find_parent_stages(pipeline$stages, "a"), character())
    expect_equal(find_parent_stages(pipeline$stages, "b"), "a")
    expect_equal(find_parent_stages(pipeline$stages, "d"), c("c", "a", "b"))
    expect_equal(find_parent_stages(pipeline$stages, "e"), character())
})
