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

        let ssh_login_file_str = list
            .get_named("ssh_login_file")
            .unwrap_or_else(|| {
                panic!("GNU Parallel params list must contain ssh_login_file named field")
            })
            .as_str()
            .unwrap_or_else(|| {
                panic!("GNU Parallel params ssh_login_file field must contain a string")
            });

        Self {
            ssh_login_file: Path::new(ssh_login_file_str).into(),
        }
    }
}
