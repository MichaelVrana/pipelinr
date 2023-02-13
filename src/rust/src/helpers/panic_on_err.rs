use std::fmt::Display;

pub trait PanicOnErr<T> {
    fn panic_on_error(self) -> T;
}

impl<T, E: Display> PanicOnErr<T> for Result<T, E> {
    fn panic_on_error(self) -> T {
        match self {
            Ok(val) => val,
            Err(err) => panic!("{}", err),
        }
    }
}

