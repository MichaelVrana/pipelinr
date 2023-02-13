use extendr_api::prelude::*;

mod helpers;
mod model;
mod gnu_parallel;

use gnu_parallel::gnu_parallel::GNUParallel;
use gnu_parallel::options::GNUParallelOptions;

#[extendr]
fn gnu_parallel_run_task_group(task_group: Robj, ssh_login_file: Robj) -> Robj {
    let ssh_login_file_str = ssh_login_file
        .as_str()
        .unwrap_or_else(|| panic!("ssh_login_file parameter must be a string"))
        .to_string();

    GNUParallel::new(GNUParallelOptions {
        ssh_login_file: ssh_login_file_str,
    })
    .run_task_group(&task_group.into())
    .into_robj()
}

extendr_module! {
    mod pipelinr;
    fn gnu_parallel_run_task_group;
}
