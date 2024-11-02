use serde::{Deserialize, Serialize};
use url::Url;
use uuid::Uuid;
use worker::*;

#[derive(Debug, Deserialize, Serialize)]
struct GenericResponse {
    status: u16,
    message: String,
}

#[event(fetch)]
async fn main(request: Request, env: Env, _context: Context) -> Result<Response> {
    Router::new()
        .get("/", index_route)
        .post("/", index_route)
        .post_async("/create", handle_create)
        .get_async("/:key", handle_url_expand)
        .run(request, env)
        .await
}

// handles `GET /` and `POST /`
pub fn index_route(_request: Request, _context: RouteContext<()>) -> worker::Result<Response> {
    Response::ok("zkgm")
}

// handles `POST /create --data-binary 'https://example.com/foo/bar'`
pub async fn handle_create(
    mut request: Request,
    context: RouteContext<()>,
) -> worker::Result<Response> {
    let url = request.text().await?;
    if Url::parse(&url).is_err() {
        return Response::error("provided url is not valid", 400);
    }

    let random_uuid = Uuid::new_v4();
    let key = random_uuid.to_string()[0..6].to_string();
    let insert_new = context.kv("KV")?.put(&key, url).unwrap().execute().await;

    if insert_new.is_err() {
        return Response::error("failed to insert new key", 500);
    }

    Response::ok(&key)
}

// checks `GET /:key{[0-9a-z]{6}}`
pub async fn handle_url_expand(
    request: Request,
    context: RouteContext<()>,
) -> worker::Result<Response> {
    let key = &request.path().to_string()[1..];
    if key.len() != 6 || !key.chars().all(|char| char.is_alphanumeric()) {
        return Response::error("invalid key: ".to_string() + key, 400);
    }

    let expanded_url = context.kv("KV")?.get(key).text().await?;
    if expanded_url.is_some() {
        return Response::redirect(Url::parse(&expanded_url.unwrap()).unwrap());
    }

    let environment = context.env.var("ENVIRONMENT").unwrap().to_string();
    let base_url = match environment.as_str() {
        "development" => "http://localhost:8787",
        _ => &request.url().unwrap().origin().ascii_serialization(),
    };

    Response::redirect(Url::parse(base_url).unwrap())
}
