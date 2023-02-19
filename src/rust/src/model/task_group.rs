use extendr_api::{Conversions, Robj};

use crate::helpers::get_named::GetNamed;

use super::task::Task;

pub struct TaskGroup {
    pub stage_name: String,
    pub tasks: Vec<Task>,
}

impl From<Robj> for TaskGroup {
    fn from(obj: Robj) -> Self {
        let list = obj
            .as_list()
            .unwrap_or_else(|| panic!("Task group object must be a list"));

        let stage_name = list
            .get_named("stage_name")
            .unwrap_or_else(|| panic!("Task group object must have a stage name"))
            .as_str()
            .unwrap_or_else(|| panic!("Task group ID must be a string"))
            .to_string();

        let tasks: Vec<Task> = list
            .get_named("tasks")
            .unwrap_or_else(|| panic!("Task group object must contain tasks"))
            .as_list()
            .unwrap_or_else(|| panic!("Task group tasks object must be a list"))
            .iter()
            .map(|(_, obj)| obj.into())
            .collect();

        Self { stage_name, tasks }
    }
}
