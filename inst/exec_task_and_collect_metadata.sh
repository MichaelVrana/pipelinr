#!/bin/sh

task_filename="$1"

Rscript exec_task.R "$task_filename"
Rscript collect_metadata.R "$task_filename" "$?"
