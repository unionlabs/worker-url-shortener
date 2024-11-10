use std::result::Result;

use worker::*;

#[derive(Debug, Clone, PartialEq)]
pub enum KvError {
    Var(String),
    Secret(String),
}

pub fn get_secret(name: &str, env: &Env) -> Result<String, KvError> {
    env.secret(name)
        .map(|value| value.to_string())
        .map_err(|error| KvError::Secret(error.to_string()))
}

pub fn get_var(name: &str, env: &Env) -> Result<String, KvError> {
    env.var(name)
        .map(|value| value.to_string())
        .map_err(|error| KvError::Var(error.to_string()))
}
