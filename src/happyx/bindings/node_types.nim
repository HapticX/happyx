import
  denim,
  regex,
  websocketx,
  std/asyncdispatch,
  std/httpcore,
  std/httpx,
  std/json,
  std/strtabs,
  std/strutils,
  ../ssr/utils


type
  ResponseObj* = object
    data*: string
    statusCode*: int
    headers*: napi_value
  FileResponseObj* = object
    filename*: string
    statusCode*: int
    asAttachment*: bool
  JsonResponseObj* = object
    data*: JsonNode
    statusCode*: int
    headers*: napi_value
  HtmlResponseObj* = object
    data*: string
    statusCode*: int
    headers*: napi_value
  Route* = object
    path*: string
    purePath*: string
    httpMethod*: seq[string]
    pattern*: Regex2
    handler*: string
    docs*: string
  HandlerParam* = object
    name*, paramType*: string
  RequestModelData* = object
    name*: string
    fields*: seq[tuple[key, val: string]]
  RequestModels* = object
    requestModels*: seq[RequestModelData]
  WebSocketState* {.pure, size: sizeof(int8).} = enum
    wssConnect,
    wssOpen,
    wssClose,
    wssHandshakeError,
    wssMismatchProtocol,
    wssError
  WebSocket* = object
    data*: string
    ws*: websocketx.WebSocket
    state*: WebSocketState


template jsObj*(arg: untyped): untyped = denim.`%*`(arg)


proc newWebSocketObj*(ws: websocketx.WebSocket, data: string = ""): node_types.WebSocket =
  node_types.WebSocket(ws: ws, data: data, state: wssOpen)


var requestModelsHidden* = RequestModels(requestModels: @[])


proc toJsObj*(headers: HttpHeaders | StringTableRef): napi_value =
  var arr: array[0, (string, napi_value)] = []
  result = jsObj(arr)
  for key, val in headers.pairs():
    result[key] = jsObj(val)


proc toJsObj*(obj: JsonNode): napi_value =
  if obj.kind == JObject:
    var arr: array[0, (string, napi_value)] = []
    result = jsObj(arr)
    for key, val in obj.pairs():
      case val.kind
      of JBool:
        result[key] = jsObj(val.getBool)
      of JFloat:
        result[key] = jsObj(val.getFloat)
      of JInt:
        result[key] = jsObj(val.getInt)
      of JString:
        result[key] = jsObj(val.getStr)
      of JArray, JObject:
        result[key] = val.toJsObj()
      else:
        discard
  else:
    var arr: array[0, napi_value] = []
    result = jsObj(arr)
    for val in obj.items():
      case val.kind
      of JBool:
        discard callMethod(result, "push", [jsObj(val.getBool)])
      of JFloat:
        discard callMethod(result, "push", [jsObj(val.getFloat)])
      of JInt:
        discard callMethod(result, "push", [jsObj(val.getInt)])
      of JString:
        discard callMethod(result, "push", [jsObj(val.getStr)])
      of JArray, JObject:
        discard callMethod(result, "push", [val.toJsObj()])
      else:
        discard


proc toJsonNode*(obj: napi_value): JsonNode =
  case obj.kind
  of napi_boolean:
    result = newJBool(obj.getBool)
  of napi_number:
    result = newJInt(obj.getInt)
  of napi_string:
    result = newJString(obj.getStr)
  of napi_object:
    if obj.isArray():
      result = newJArray()
      for i in obj:
        result.add(i.toJsonNode())
    else:
      result = newJObject()
      for key, val in obj.pairs():
        result[key] = val.toJsonNode()
  else:
    discard


proc toHttpHeaders*(obj: napi_value): HttpHeaders =
  if obj.kind == napi_object and not obj.isArray():
    result = newHttpHeaders()
    for k, v in obj.pairs():
      result[k] = $v


proc initRoute*(path, purePath: string, httpMethod: seq[string], pattern: Regex2, handler, docs: string): Route =
  Route(path: path, purePath: purePath, httpMethod: httpMethod, pattern: pattern, handler: handler, docs: docs)

proc hasHttpMethod*(self: Route, httpMethod: string | seq[string] | openarray[string]): bool =
  when httpMethod is string:
    return self.httpMethod.contains(httpMethod)
  else:
    for i in httpMethod:
      if self.httpMethod.contains(i):
        return true
    return false


proc newHandlerParams*(args: openarray[string], annotations: JsonNode): seq[HandlerParam] =
  result = @[]
  for arg in args:
    if annotations.hasKey(arg):
      result.add(HandlerParam(name: arg, paramType: annotations[arg].str))
    else:
      result.add(HandlerParam(name: arg, paramType: "any"))


proc contains*(params: seq[HandlerParam], key: string): bool =
  for param in params:
    if param.name == key:
      return true
  false


proc hasParamType*(params: seq[HandlerParam], key: string): bool =
  for param in params:
    if param.paramType == key:
      return true
  false


proc contains*(self: RequestModels, name: string): bool =
  for m in self.requestModels:
    if m.name == name:
      return true
  false


proc getParamType*(params: seq[HandlerParam], key: string): string =
  for param in params:
    if param.name == key:
      return param.paramType
  ""


proc `[]`*(params: seq[HandlerParam], key: string): string = params.getParamType(key)


proc `[]`*(self: RequestModels, name: string): RequestModelData =
  for m in self.requestModels:
    if m.name == name:
      return m


proc getParamName*(params: seq[HandlerParam], paramType: string): string =
  for param in params:
    if param.paramType.toLower() == paramType.toLower():
      return param.name
  ""

