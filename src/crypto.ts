export async function createKey(kv: KVNamespace, url: string): Promise<string> {
  const uuid = crypto.randomUUID()
  const key = uuid.substring(0, 6)
  const result = await kv.get(key)

  if (result) return await createKey(kv, url)
  await kv.put(key, url)

  return key
}
