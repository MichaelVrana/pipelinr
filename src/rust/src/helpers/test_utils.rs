use extendr_api::prelude::*;

pub fn load_dsl() {
    R!("
        setwd('../../..')
        source('./dsl/prototype.R')
        setwd('engine/src/rust')
    ")
    .unwrap();
}
