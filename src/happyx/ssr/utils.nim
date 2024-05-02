## # SSR Utils
## 
## provides some utils to working at server-side
## 
import
  std/json,
  std/httpcore,
  std/options



proc toJsonNode*(headers: HttpHeaders | Option[HttpHeaders]): JsonNode =
  ## Converts [HttpHeaders](https://nim-lang.org/docs/httpcore.html#HttpHeaders)
  ## to [JsonNode](https://nim-lang.org/docs/json.html#JsonNode)
  result = newJObject()
  when headers is HttpHeaders:
    for k, v in headers.pairs():
      result[k] = newJString(v)
  else:
    for k, v in headers.get().pairs():
      result[k] = newJString(v)


proc toHttpHeaders*(json: JsonNode): HttpHeaders =
  ## Converts [JsonNode](https://nim-lang.org/docs/json.html#JsonNode)
  ## to [HttpHeaders](https://nim-lang.org/docs/httpcore.html#HttpHeaders)
  result = newHttpHeaders()
  for k, v in json.pairs():
    result[k] = v.getStr

