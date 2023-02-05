use extendr_api::{Conversions, Robj};

use super::task::Task;

pub struct TaskGroup {
    pub tasks: Vec<Task>,
}

impl From<Robj> for TaskGroup {
    fn from(obj: Robj) -> Self {
        let list = obj
            .as_list()
            .unwrap_or_else(|| panic!("Task group object must be a list"));

        let tasks: Vec<Task> = list.iter().map(|(_, obj)| obj.into()).collect();

        TaskGroup { tasks }
    }
}
