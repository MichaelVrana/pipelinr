use extendr_api::prelude::*;

mod gnu_parallel;
mod helpers;
mod model;

use gnu_parallel::gnu_parallel::GNUParallel;
use gnu_parallel::options::GNUParallelOptions;

#[extendr]
fn gnu_parallel_run_task_group(task_group: Robj, ssh_login_file: Robj) {
    let ssh_login_file_str = ssh_login_file
        .as_str()
        .unwrap_or_else(|| panic!("ssh_login_file parameter must be a string"))
        .to_string();

    GNUParallel::new(GNUParallelOptions {
        ssh_login_file: ssh_login_file_str,
    })
    .run_task_group(&task_group.into());
}

extendr_module! {
    mod pipelinr;
    fn gnu_parallel_run_task_group;
}
