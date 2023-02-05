use extendr_api::prelude::*;

mod helpers;
mod model;

mod gnu_parallel;

use extendr_api::{
    prelude::{extendr, extendr_module},
    R, Robj,
};

#[extendr]
fn gnu_parallel_run_task_group(task_group_obj: Robj) -> Robj {
    R!("NULL").unwrap()
}

extendr_module! {
    mod engine;
    fn gnu_parallel_run_task_group;
}
