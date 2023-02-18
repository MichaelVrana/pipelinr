use super::options::GNUParallelOptions;
use crate::{helpers::panic_on_err::PanicOnErr, model::task_group::TaskGroup};
use extendr_api::prelude::*;
use std::{
    fs::create_dir_all,
    path::{PathBuf},
    process::Command,
};

pub struct GNUParallel {
    options: GNUParallelOptions,
}

impl GNUParallel {
    pub fn new(params: GNUParallelOptions) -> Self {
        Self { options: params }
    }

    fn create_task_group_dir(&self, command: &mut Command, task_group: &TaskGroup) -> PathBuf {
        let dir_path = PathBuf::from(self.options.pipeline_dir.clone()).join(task_group.id.clone());

        command.current_dir(dir_path.clone());

        if let Err(error) = create_dir_all(dir_path.clone()) {
            rprintln!("Warning: Failed to create GNU Parallel IO directory for task group id {}. Reason: {}", task_group.id, error.to_string());
        }

        dir_path
    }

    fn add_ssh_args(&self, command: &mut Command) {
        command.args([
            "--sshloginfile",
            format!("../../{}", self.options.ssh_login_file).as_str(),
            "--trc",
            "{.}_out.qs",
            "./exec_task_and_collect_metadata.sh",
            ":::",
        ]);
    }

    fn add_non_ssh_args(&self, command: &mut Command) {
        panic!("Not implemented");
        // command.args(["TODO/exec_task_and_collect_metadata.sh", ":::"]);
    }

    fn add_task_args(&self, command: &mut Command, task_group: &TaskGroup, dir_path: &PathBuf) {
        for (task_idx, task) in task_group.tasks.iter().enumerate() {
            let task_file_name = format!("task_{}.qs", task_idx);
            let task_file_path = dir_path.join(task_file_name.clone());

            let task_payload = list!(body = task.body.clone(), args = task.args.clone());

            call!("qsave", task_payload, task_file_path.to_str().unwrap()).panic_on_error();

            command.arg(task_file_name);
        }
    }

    pub fn run_task_group(&self, task_group: &TaskGroup) {
        let mut command = Command::new("parallel");

        let dir_path = self.create_task_group_dir(&mut command, task_group);

        if !self.options.ssh_login_file.is_empty() {
            self.add_ssh_args(&mut command);
        } else {
            self.add_non_ssh_args(&mut command);
        }

        R!("suppressPackageStartupMessages(library(qs))").panic_on_error();

        self.add_task_args(&mut command, task_group, &dir_path);

        let status = command.status().panic_on_error();

        if !status.success() {
            panic!(
                "GNU Parallel exited with error code {}",
                status.code().unwrap()
            )
        }
    }
}
