use std::{fmt::{self}, io, str::Utf8Error};


pub type Result<T> = core::result::Result<T, Error>;

#[derive(Debug)]
pub enum Error {
    Io(io::Error),
    Git(git2::Error),
    Keys(ssh_key::Error),
    Utf8Err(Utf8Error)
}

impl From<Utf8Error> for Error {
    fn from(err: Utf8Error) -> Self {
        Error::Utf8Err(err)
    }
}

impl From<io::Error> for Error {
    fn from(err: io::Error) -> Self {
        Error::Io(err)
    }
}

impl From<git2::Error> for Error {
    fn from(err: git2::Error) -> Self {
        Error::Git(err)
    }
}

impl From<ssh_key::Error> for Error {
    fn from(err: ssh_key::Error) -> Self {
        Error::Keys(err)
    }
}

impl fmt::Display for Error {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Error::Io(e) => write!(f, "IO error: {}", e),
            Error::Git(e) => write!(f, "Git error: {}", e),
            Error::Keys(e) => write!(f, "Ssh key error: {}", e),
            Error::Utf8Err(e) => write!(f, "Utf8 error: {}", e)
        }
    }
}