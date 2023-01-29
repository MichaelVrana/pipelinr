use extendr_api::{Robj, Conversions};

use crate::stage::Stage;

pub struct Pipeline {
    stages: Vec<Stage>
}

impl From<&Robj> for Pipeline {
    fn from(value: &Robj) -> Self {
         
    }
}