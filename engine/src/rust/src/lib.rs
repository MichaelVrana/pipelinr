mod pipeline;
mod stage;

use extendr_api::prelude::*;

#[extendr]
fn gnu_parallel_run_pipeline(pipeline_obj: Robj) -> Robj {
    match pipeline_obj.eval_promise() {
        Err(err) => throw_r_error(format!(
            "Failed to evaluate pipeline object promise {}",
            err.to_string()
        ))
        .into(),
        Ok(pipeline_obj) => {
            
        },
    }
}

extendr_module! {
    mod engine;
    fn gnu_parallel_run_pipeline;
}
