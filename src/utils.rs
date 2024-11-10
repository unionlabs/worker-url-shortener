use worker::*;

pub fn get_secret(name: &str, env: &Env) -> Option<String> {
    match env.secret(name) {
        Ok(value) => Some(value.to_string()),
        Err(_) => None,
    }
}

pub fn get_var(name: &str, env: &Env) -> Option<String> {
    match env.var(name) {
        Ok(value) => Some(value.to_string()),
        Err(_) => None,
    }
}
