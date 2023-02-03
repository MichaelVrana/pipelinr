use extendr_api::{Attributes, Conversions, Function, List, Robj};

pub struct Stage {
    stage_obj: Robj,
    inputs: List,
    body: Function,
}

const STAGE_INPUTS_CLASS: &str = "quosures";

impl From<&Robj> for Stage {
    fn from(obj: &Robj) -> Self {
        let inputs = obj
            .get_attrib("inputs")
            .unwrap_or_else(|| panic!("Stage object is missing inputs attribute"))
            .as_list()
            .unwrap_or_else(|| panic!("Inputs object must be a list"));

        let body = obj
            .get_attrib("body")
            .unwrap_or_else(|| panic!("Stage object is missing body attribute"))
            .as_function()
            .unwrap_or_else(|| panic!("Stage body must be a function"));

        let mut input_classes = inputs
            .class()
            .unwrap_or_else(|| panic!("Stage inputs cannot be of no class"));

        if !input_classes.any(|class| class == STAGE_INPUTS_CLASS) {
            panic!("Stage inputs must be of class {}", STAGE_INPUTS_CLASS);
        }

        Stage {
            stage_obj: obj.clone(),
            inputs,
            body,
        }
    }
}

impl From<Robj> for Stage {
    fn from(obj: Robj) -> Self {
        obj.into()
    }
}
