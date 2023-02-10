use super::options::GNUParallelOptions;
use crate::{helpers::panic_on_err::PanicOnErr, model::task_group::TaskGroup};
use extendr_api::prelude::*;
use std::{fs::create_dir_all, path::Path, process::Command};

pub struct GNUParallel {
    options: GNUParallelOptions,
}

impl GNUParallel {
    pub fn new(params: GNUParallelOptions) -> Self {
        Self { options: params }
    }

    pub fn run_task_group(&self, task_group: &TaskGroup) -> List {
        let mut command = Command::new("parallel");

        let dir_path = Path::new("gnu_parallel_tasks").join(task_group.id.clone());

        command.current_dir(dir_path.clone());

        if let Err(error) = create_dir_all(dir_path.clone()) {
            rprintln!("Warning: Failed to create GNU Parallel IO directory for task group id {}. Reason: {}", task_group.id, error.to_string());
        }

        if !self.options.ssh_login_file.is_empty() {
            command.args([
                "--sshloginfile",
                format!("../../{}", self.options.ssh_login_file).as_str(),
                "--trc",
                "{.}_out.qs",
                "Rscript",
                "exec_task.R",
                "{}",
                ":::",
            ]);
        } else {
            command.args(["Rscript", "TODO/exec_task.R", "{}", ":::"]);
        }

        call!("library", "qs").panic_on_error();

        for (task_idx, task) in task_group.tasks.iter().enumerate() {
            let task_file_name = format!("task_{}.qs", task_idx);
            let task_file_path = dir_path.join(task_file_name.clone());

            let task_payload = list!(body = task.body.clone(), args = task.args.clone());

            call!("qsave", task_payload, task_file_path.to_str().unwrap()).panic_on_error();

            command.arg(task_file_name);
        }

        let status_result = command.status();

        let status = status_result.panic_on_error();

        if !status.success() {
            panic!(
                "GNU Parallel exited with error code {}",
                status.code().unwrap()
            )
        }

        List::from_iter(task_group.tasks.iter().enumerate().map(|(task_index, _)| {
            let task_result_file_path = dir_path.join(format!("task_{}_out.qs", task_index));

            call!("qload", task_result_file_path.to_str().unwrap()).panic_on_error()
        }))
    }
}
