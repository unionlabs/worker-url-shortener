#![warn(clippy::all)]
use serde::{Deserialize, Serialize};
use serde_json::Value;
use url::Url;
use worker::{console_log, event, Context, Env, Request, Response, Result, RouteContext, Router};

#[derive(Deserialize, Serialize)]
struct Record {
    id: u64,
    url: String,
    created_at: String,
}

const DEV_ROUTES: [&str; 2] = ["/list", "/env"];

#[event(fetch)]
async fn fetch(request: Request, env: Env, _context: Context) -> Result<Response> {
    let environment = env.var("ENVIRONMENT").unwrap().to_string();
    if environment.trim().is_empty() {
        return Response::error("not allowed", 403);
    }

    let mut router = Router::new()
        .get("/", |_, _| Response::ok("zkgm"))
        .post("/", |_, _| Response::ok("zkgm"))
        .post_async("/create", handle_create)
        .get_async("/:key", handle_url_expand);

    let url = request.url()?;
    if DEV_ROUTES.contains(&url.path()) {
        if let Some(key) = url.query_pairs().find(|(k, _)| k == "key").map(|(_, v)| v) {
            console_log!("key: {:?}", key);
            let stored_key = env.secret("DEV_ROUTES_KEY").unwrap().to_string();
            if stored_key != key {
                return router.run(request, env).await;
            }
            router = router.get_async("/list", dev_handle_list_urls);
        }
    }

    router.run(request, env).await
}

// handles `POST /create --data-binary 'https://example.com/foo/bar'`
pub async fn handle_create(
    mut request: Request,
    context: RouteContext<()>,
) -> worker::Result<Response> {
    let payload_url = request.text().await?;
    if Url::parse(&payload_url).is_err() {
        return Response::error("provided url is not valid", 400);
    }

    let d1 = context.env.d1("DB")?;
    let statement = d1.prepare("INSERT INTO urls (url) VALUES (?)");
    let query = statement.bind(&[payload_url.into()]);
    let result = query?.run().await?;

    if result.error().is_some() {
        return Response::error("failed to insert new key", 500);
    }

    let query_statement = d1.prepare("SELECT id FROM urls ORDER BY id DESC LIMIT 1");
    let query = query_statement.bind(&[]);
    let result = query?.first::<Value>(None).await?.unwrap();

    if let Value::Object(object) = result {
        if let Some(Value::Number(id)) = object.get("id") {
            return Response::ok(format!(
                "https://{}/{}",
                request.url().unwrap().host_str().unwrap(),
                id
            ));
        }
    }
    Response::error("failed to insert new key", 500)
}

// checks `GET /:key{[0-9]}`
pub async fn handle_url_expand(
    request: Request,
    context: RouteContext<()>,
) -> worker::Result<Response> {
    let url = request.url()?;
    let key = url.path().trim_start_matches('/');

    if key.parse::<u64>().is_err() || key.is_empty() {
        return Response::error("invalid key: ".to_string() + key, 400);
    }

    let query = context
        .env
        .d1("DB")?
        .prepare("SELECT url FROM urls WHERE id = ?")
        .bind(&[key.into()]);
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

// dev-only route: quick way to check records are inserted
pub async fn dev_handle_list_urls(
    _request: Request,
    context: RouteContext<()>,
) -> worker::Result<Response> {
    let d1 = context.env.d1("DB")?;
    let statement = d1.prepare("SELECT * FROM urls");
    // let query = statement.bind(&[])?;
    // let result = statement.all().await?;

    let records: Vec<Record> = statement.all().await?.results()?;
    Response::from_json(&records)
}
