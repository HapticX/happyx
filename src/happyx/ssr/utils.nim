## # SSR Utils
## 
import
  json,
  httpcore,
  options



proc toJsonNode*(headers: HttpHeaders | Option[HttpHeaders]): JsonNode =
  result = newJObject()
  when headers is HttpHeaders:
    for k, v in headers.pairs():
      result[k] = newJString(v)
  else:
    for k, v in headers.get().pairs():
      result[k] = newJString(v)


proc toHttpHeaders*(json: JsonNode): HttpHeaders =
  result = newHttpHeaders()
  for k, v in json.pairs():
    result[k] = v.getStr

