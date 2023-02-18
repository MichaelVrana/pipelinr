#!/bin/bash

$(cd tests/test_worker && ./run_test_workers.sh)
PARALLEL_SSH="ssh -F $(pwd)/tests/test_worker/ssh.config" Rscript --vanilla --default-packages=devtools -e 'test()'