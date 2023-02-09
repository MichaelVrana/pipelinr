use std::path::Path;

use extendr_api::{Conversions, Robj};

use crate::helpers::get_named::GetNamed;

pub struct GNUParallelParams {
    pub ssh_login_file: Option<Box<Path>>,
}

impl From<Robj> for GNUParallelParams {
    fn from(obj: Robj) -> Self {
        let list = obj
            .as_list()
            .unwrap_or_else(|| panic!("GNU Parallel params object must be a list"));

        let ssh_login_file = list
            .get_named("ssh_login_file")
            .map(|obj| {
                let str = obj.as_str().unwrap_or_else(|| panic!("GNU Parallel params object must be a string"));
                Box::from(Path::new(str))
            });

        Self {
            ssh_login_file
        }
    }
}
