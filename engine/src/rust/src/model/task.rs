use crate::helpers::get_named::GetNamed;
use extendr_api::{Conversions, Function, List, Robj};

pub struct Task {
    pub args: List,
    pub body: Function,
}

impl From<Robj> for Task {
    fn from(obj: Robj) -> Self {
        let list = obj
            .as_list()
            .unwrap_or_else(|| panic!("Task object must be a list"));

        Task {
            args: list
                .get_named("args")
                .unwrap_or_else(|| panic!("Task object is missing args"))
                .as_list()
                .unwrap_or_else(|| panic!("Task object args must be a list")),
            body: list
                .get_named("body")
                .unwrap_or_else(|| panic!("Task object is missing body"))
                .as_function()
                .unwrap_or_else(|| panic!("Task object body must be a function")),
        }
    }
}
