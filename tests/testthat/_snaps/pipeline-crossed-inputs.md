# Pipeline evaluates crossed inputs

    Code
      actual
    Output
      [[1]]
      [[1]][[1]]
      [1] 2
      
      [[1]][[2]]
      [1] "a"
      
      
      [[2]]
      [[2]][[1]]
      [1] 6
      
      [[2]][[2]]
      [1] "a"
      
      
      [[3]]
      function(iters) {
              if (all(iters, function(iter) iter$done)) return(make_empty_iter())
      
              next_iter <- function() {
                  iterate <- TRUE
      
                  imap(iters, function(iter, idx) {
                      if (!iterate) return(iter)
                      if (iter$done) return(original_iters[[idx]])
      
                      iterate <<- FALSE
                      iter$next_iter()
                  }) %>% cross()
              }
      
              make_iter(value = map(iters, function(iter) iter$value), next_iter = next_iter)
          }
      <environment: 0x55569e03da38>
      
      [[4]]
      function(iters) {
              if (all(iters, function(iter) iter$done)) return(make_empty_iter())
      
              next_iter <- function() {
                  iterate <- TRUE
      
                  imap(iters, function(iter, idx) {
                      if (!iterate) return(iter)
                      if (iter$done) return(original_iters[[idx]])
      
                      iterate <<- FALSE
                      iter$next_iter()
                  }) %>% cross()
              }
      
              make_iter(value = map(iters, function(iter) iter$value), next_iter = next_iter)
          }
      <bytecode: 0x55569e018c88>
      <environment: 0x55569e028a58>
      
      [[5]]
      [[5]][[1]]
      [1] 6
      
      [[5]][[2]]
      [1] "b"
      
      
      [[6]]
      [[6]][[1]]
      [1] 4
      
      [[6]][[2]]
      [1] "b"
      
      
      [[7]]
      [[7]][[1]]
      [1] 2
      
      [[7]][[2]]
      [1] "b"
      
      
      [[8]]
      [[8]][[1]]
      [1] 4
      
      [[8]][[2]]
      [1] "a"
      
      

