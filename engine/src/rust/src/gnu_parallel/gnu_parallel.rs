use std::{env::set_current_dir, fs::create_dir, path::Path, process::Command};

use extendr_api::prelude::*;

use crate::{helpers::panic_on_err::PanicOnErr, model::task_group::TaskGroup};

use super::params::GNUParallelParams;

pub struct GNUParallel {
    params: GNUParallelParams,
}

impl GNUParallel {
    pub fn run_task_group(&self, task_group: &TaskGroup) -> List {
        let mut command = Command::new("parallel");

        let dir_path = Path::new("gnu_parallel_tasks").join(task_group.id);

        if let Err(error) = create_dir(dir_path) {
            rprintln!("Warning: Failed to create GNU Parallel IO directory for task group id {}. Reason: {}", task_group.id, error.to_string());
        }

        set_current_dir(dir_path).panic_on_error();

        match self.params.ssh_login_file {
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
                command.args(["Rscript", "../exec_task.R", "{}", ":::"]);
            }
        }

        call!("library", "qs").panic_on_error();

        for (task_idx, task) in task_group.tasks.iter().enumerate() {
            let task_file_path = format!("task_{}.qs", task_idx);

            call!(
                "qsave",
                list!(body = task.body, args = task.args),
                Rstr::from_string(task_file_path.as_str())
            )
            .panic_on_error();

            command.arg(task_file_path);
        }

        let command_output = command.output().panic_on_error();

        if !command_output.status.exit_ok() {
            panic!(
                "GNU Parallel exited with error code {}",
                command_output.status.code().unwrap()
            )
        }
    }
}

impl From<GNUParallelParams> for GNUParallel {
    fn from(params: GNUParallelParams) -> Self {
        Self { params }
    }
}
