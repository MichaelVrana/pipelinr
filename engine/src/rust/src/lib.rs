use extendr_api::prelude::*;

mod helpers;
mod model;

mod gnu_parallel;

use extendr_api::{
    prelude::{extendr, extendr_module},
    Robj,
};
use gnu_parallel::gnu_parallel::GNUParallel;

#[extendr]
fn gnu_parallel_run_task_group(parallel_params: Robj, task_group: Robj) -> Robj {
    GNUParallel::new(parallel_params.into())
        .run_task_group(&task_group.into())
        .into_robj()
}

extendr_module! {
    mod engine;
    fn gnu_parallel_run_task_group;
}
