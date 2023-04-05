foo <- "foo"

make_pipeline(
    a = stage(function() 1:3),
    b = stage(function(a) a)
)