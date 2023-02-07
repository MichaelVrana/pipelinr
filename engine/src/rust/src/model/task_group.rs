use extendr_api::{Conversions, Robj};

use crate::helpers::get_named::GetNamed;

use super::task::Task;

pub struct TaskGroup {
    pub id: String,
    pub tasks: Vec<Task>,
}

impl From<Robj> for TaskGroup {
    fn from(obj: Robj) -> Self {
        let list = obj
            .as_list()
            .unwrap_or_else(|| panic!("Task group object must be a list"));

        let id = list
            .get_named("id")
            .unwrap_or_else(|| panic!("Task group object must have an ID"))
            .as_str()
            .unwrap_or_else(|| panic!("Task group ID must be a string"))
            .to_string();

        let tasks: Vec<Task> = list.iter().map(|(_, obj)| obj.into()).collect();

        Self { id, tasks }
    }
}
