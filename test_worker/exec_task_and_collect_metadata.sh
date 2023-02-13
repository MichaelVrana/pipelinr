#!/bin/sh

task_filename="$1"

stdout_filename="$task_filename".stdout
stderr_filename="$task_filename".stderr

Rscript exec_task.R "$task_filename" 1 > "$stdout_filename" 2 > "$stderr_filename"
Rscript collect_metadata.R "$task_filename" "$?" "$stdout_filename" "$stderr_filename"
