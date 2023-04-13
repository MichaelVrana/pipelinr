#!/bin/bash

$(cd ssh_worker && ./run_test_workers.sh)
PARALLEL_SSH="ssh -F $(pwd)/ssh_worker/ssh.config" Rscript --vanilla --default-packages=devtools -e 'test()'