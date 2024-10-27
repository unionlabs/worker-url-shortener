import { Hono } from 'hono'
import { csrf } from 'hono/csrf'
import { showRoutes } from 'hono/dev'
import { createKey } from '#crypto.ts'
import { timeout } from 'hono/timeout'
import { requestId } from 'hono/request-id'
import { prettyJSON } from 'hono/pretty-json'
import { secureHeaders } from 'hono/secure-headers'
import { HTTPException } from 'hono/http-exception'

type IsValidUrl = (url: string) => boolean
const isValidUrl: IsValidUrl = url => new URLPattern({ protocol: '*', hostname: '*' }).test(url)

const app = new Hono<{ Bindings: Env }>()

app.use(prettyJSON())
app.use(secureHeaders())
app.use('*', requestId())
app.use('*', timeout(5_000))

app.on(['GET', 'POST'], '/', _ => new Response('zkgm'))

/** start of relevant url shorting logic */

app.get('/:key{[0-9a-z]{6}}', async context => {
  const key = context.req.param('key')
  const url = await context.env.KV.get(key)

  if (url === null) return context.redirect('/')
  return context.redirect(url)
})

app.post('/create', csrf(), async context => {
  const url = await context.req.text()
  if (!isValidUrl(url)) throw new Error('provided url is not valid')

  const key = await createKey(context.env.KV, url)

  return new Response(key)
})

/** end of relevant url shorting logic */

app.notFound(context => {
  const report = `environment: ${context.env.ENVIRONMENT}\nid: ${context.get('requestId')}`
  const message = `if this is unexpected, open an issue and include everything under this line\n\n${report}`
  return new Response(`zkgn 🐻🐻 📉📉\n\n${message}`, { status: 404 })
})

app.onError((error, context) => {
  const report = `environment: ${context.env.ENVIRONMENT}\nid: ${context.get('requestId')}\nerror: ${error.message}`
  const message = `if this is unexpected, open an issue and include everything under this line\n\n${report}`

  if (error instanceof HTTPException) return error.getResponse()

  return new Response(`zkgn 🐻🐻 📉📉\n\n${message}`, { status: 404 })
})

app.get('/kv', async context => {
  if (context.env.ENVIRONMENT !== 'development') return context.notFound()

  const kvList = await context.env.KV.list()
  return context.json(kvList)
})

showRoutes(app, { verbose: true, colorize: true })

export default {
  port: 8_787,
  fetch: app.fetch
}
