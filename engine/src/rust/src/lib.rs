use extendr_api::prelude::*;

mod helpers;
mod pipeline;
mod stage;

use extendr_api::{
    prelude::{extendr, extendr_module},
    r, Robj,
};
use pipeline::Pipeline;

#[extendr]
fn gnu_parallel_run_pipeline(pipeline_obj: Robj) -> Robj {
    let pipeline: Pipeline = pipeline_obj.into();
    r!("NULL")
}

extendr_module! {
    mod engine;
    fn gnu_parallel_run_pipeline;
}
