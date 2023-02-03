use extendr_api::{Attributes, Conversions, Robj};

use crate::stage::Stage;

pub struct Pipeline {
    stages: Vec<Stage>,
}

impl From<&Robj> for Pipeline {
    fn from(obj: &Robj) -> Self {
        let stages_list = obj
            .get_attrib("stages")
            .unwrap_or_else(|| panic!("Pipeline stages attribute is missing"))
            .as_list()
            .unwrap_or_else(|| panic!("Pipeline stages object must be a list"));

        let stages = stages_list
            .iter()
            .map(|(_, stage_obj)| stage_obj.into())
            .collect();

        Pipeline { stages }
    }
}

impl From<Robj> for Pipeline {
    fn from(value: Robj) -> Self {
        value.into()
    }
}
