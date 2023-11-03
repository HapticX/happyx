## # SSR Utils
## 
import
  json,
  httpcore



proc toJsonNode*(headers: HttpHeaders): JsonNode =
  result = newJObject()
  for k, v in headers.pairs():
    result[k] = newJString(v)


proc toHttpHeaders*(json: JsonNode): HttpHeaders =
  result = newHttpHeaders()
  for k, v in json.pairs():
    result[k] = v.getStr

