use super::params::GNUParallelParams;
use crate::{helpers::panic_on_err::PanicOnErr, model::task_group::TaskGroup};
use extendr_api::prelude::*;
use std::{env::set_current_dir, fs::create_dir, path::Path, process::Command};

pub struct GNUParallel {
    params: GNUParallelParams,
}

impl GNUParallel {
    pub fn new(params: GNUParallelParams) -> Self {
        Self { params }
    }

    pub fn run_task_group(&self, task_group: &TaskGroup) -> List {
        let mut command = Command::new("parallel");

        let dir_path = Path::new("gnu_parallel_tasks").join(task_group.id.clone());

        if let Err(error) = create_dir(dir_path.clone()) {
            rprintln!("Warning: Failed to create GNU Parallel IO directory for task group id {}. Reason: {}", task_group.id, error.to_string());
        }

        set_current_dir(dir_path).panic_on_error();

        match &self.params.ssh_login_file {
            Some(ssh_login_file) => {
                command.args([
                    "--sshloginfile",
                    ssh_login_file.to_str().unwrap(),
                    "-trc",
                    "{.}.out.qs",
                    "Rscript",
                    "exec_task.R",
                    "{}",
                    ":::",
                ]);
            }
            None => {
                command.args(["Rscript", "TODO/exec_task.R", "{}", ":::"]);
            }
        }

        call!("library", "qs").panic_on_error();

        for (task_idx, task) in task_group.tasks.iter().enumerate() {
            let task_file_path = format!("task_{}.qs", task_idx);

            call!(
                "qsave",
                list!(body = task.body.clone(), args = task.args.clone()),
                Rstr::from_string(task_file_path.as_str())
            )
            .panic_on_error();

            command.arg(task_file_path);
        }

        let status_result = command.status();

        set_current_dir("..").panic_on_error();

        let status = status_result.panic_on_error();

        if !status.success() {
            panic!(
                "GNU Parallel exited with error code {}",
                status.code().unwrap()
            )
        }

        List::from_iter(task_group.tasks.iter().enumerate().map(|(task_index, _)| {
            let task_result_file_name = format!("task_{}.out.qs", task_index);
            call!("qload", task_result_file_name).panic_on_error()
        }))
    }
}
