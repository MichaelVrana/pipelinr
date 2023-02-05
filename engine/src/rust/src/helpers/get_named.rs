use extendr_api::{Robj, List};

pub trait GetNamed {
    fn get_named(&self, name: &str) -> Option<Robj>;
}

impl GetNamed for List {
    fn get_named(&self, name: &str) -> Option<Robj> {
        self.iter().find(|(_name, _)| *_name == name).map(|(_, value)| value)
    }
}
