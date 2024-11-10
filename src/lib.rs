use serde::{Deserialize, Serialize};
use serde_json::Value;
use url::Url;
use worker::*;

#[derive(Debug, Deserialize, Serialize)]
struct GenericResponse {
    status: u16,
    message: String,
}

#[event(fetch)]
async fn main(request: Request, env: Env, _context: Context) -> Result<Response> {
    let environment = env.var("ENVIRONMENT").unwrap().to_string();
    if environment.trim().is_empty() {
        return Response::error("not allowed", 403);
    }

    let mut router = Router::new()
        // public routes
        .get("/", index_route)
        .post("/", index_route)
        .post_async("/create", handle_create)
        .get_async("/:key", handle_url_expand);

    if environment == "development" {
        // dev-only routes
        // quick way to check records are inserted
        router = router.get_async("/list", dev_handle_list_urls);
    }

    return router.run(request, env).await;
}

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

    let d1 = context.env.d1("DB");
    let statement = d1?.prepare("INSERT INTO urls (url) VALUES (?)");
    let query = statement.bind(&[url.into()]);
    let result = query?.run().await?.success();

    if result {
        return Response::ok("ok");
    }

    Response::error("failed to insert new key", 500)
}

// checks `GET /:key{[0-9]}`
pub async fn handle_url_expand(
    request: Request,
    context: RouteContext<()>,
) -> worker::Result<Response> {
    let key = &request.path().to_string()[1..];
    if key.parse::<u64>().is_err() {
        return Response::error("invalid key: ".to_string() + key, 400);
    }

    let d1 = context.env.d1("DB");
    let statement = d1?.prepare("SELECT url FROM urls WHERE id = ?");
    let query = statement.bind(&[key.into()]);
    let result: Option<Value> = query?.first::<Value>(None).await?;

    match result {
        Some(Value::Object(object)) => {
            if let Some(Value::String(url)) = object.get("url") {
                return Response::redirect(Url::parse(url)?);
            }
            Response::error("Invalid URL format", 400)
        }
        _ => Response::error("Invalid key: ".to_string() + key, 400),
    }
}

pub async fn dev_handle_list_urls(
    _request: Request,
    context: RouteContext<()>,
) -> worker::Result<Response> {
    let d1 = context.env.d1("DB");
    let statement = d1?.prepare("SELECT * FROM urls");
    let query = statement.bind(&[]);
    let result = query?.all().await?;

    let urls: Vec<Value> = result.results()?;
    Response::from_json(&urls)
}
