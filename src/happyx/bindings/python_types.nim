import
  # Stdlib
  asyncdispatch,
  httpcore,
  strtabs,
  strutils,
  json,
  # Python lib
  nimpy,
  nimpy/py_types,
  nimpy/py_lib,
  dynlib,
  # Regex2
  regex,
  # HappyX
  ../core/constants


# WS
when enableHttpBeast:
  import websocket
else:
  import websocketx


var
  uniqueWebSocketId*: uint64 = 0


type
  HttpRequest* = ref object of PyNimObjectExperimental
    path*: string
    body*: string
    httpMethod*: string
    headers*: PPyObject
  ResponseObj* = ref object of PyNimObjectExperimental
    data*: string
    statusCode*: int
    headers*: PyObject
  FileResponseObj* = ref object of PyNimObjectExperimental
    filename*: string
    statusCode*: int
    asAttachment*: bool
  JsonResponseObj* = ref object of PyNimObjectExperimental
    data*: JsonNode
    statusCode*: int
    headers*: PyObject
  HtmlResponseObj* = ref object of PyNimObjectExperimental
    data*: string
    statusCode*: int
    headers*: PyObject
  HandlerParam* = object
    name*, paramType*: string
    reserved*: bool
  Route* = ref object of PyNimObjectExperimental
    path*: string
    purePath*: string
    httpMethod*: seq[string]
    pattern*: Regex2
    handler*: PyObject
    locals*: PyObject
    posArgs*: seq[string]
    params*: JsonNode
    handlerParams*: seq[HandlerParam]
  RequestModelData* = object
    name*: string
    pyClass*: PyObject
    fields*: seq[tuple[key, val: string]]
  RequestModels* = ref object of PyNimObjectExperimental
    requestModels*: seq[RequestModelData]
  WebSocketState* {.pure, size: sizeof(int8).} = enum
    wssConnect,
    wssOpen,
    wssClose,
    wssHandshakeError,
    wssMismatchProtocol,
    wssError
when enableHttpBeast:
  type
    WebSocket* = ref object of PyNimObjectExperimental
      id*: uint64
      ws*: websocket.AsyncWebSocket
      data*: string
      state*: WebSocketState
  proc newWebSocketObj*(ws: websocket.AsyncWebSocket, data: string = ""): python_types.WebSocket =
    inc uniqueWebSocketId
    python_types.WebSocket(ws: ws, data: data, id: uniqueWebSocketId, state: wssOpen)
else:
  type
    WebSocket* = ref object of PyNimObjectExperimental
      id*: uint64
      ws*: websocketx.WebSocket
      data*: string
      state*: WebSocketState
  proc newWebSocketObj*(ws: websocketx.WebSocket, data: string = ""): python_types.WebSocket =
    inc uniqueWebSocketId
    python_types.WebSocket(ws: ws, data: data, id: uniqueWebSocketId, state: wssOpen)


var
  requestModelsHidden* = RequestModels(requestModels: @[])


proc processWebSocket*(py, locals: PyObject) =
  discard py.eval("handler(**funcParams)", locals)


proc toPPyObject*(headers: HttpHeaders): PPyObject =
  var headersJson = newJObject()
  for key, val in headers.pairs():
    headersJson[key] = newJString(val)
  result = nimValueToPy(headersJson)


proc toHttpHeaders*(headers: PyObject): HttpHeaders =
  var
    headersObj = newHttpHeaders()
    data = headers.to(JsonNode)
  for key, val in data.pairs():
    headersObj[key] = val.getStr
  headersObj


proc newHandlerParams*(args: openarray[string], annotations: JsonNode): seq[HandlerParam] =
  result = @[]
  for arg in args:
    if annotations.hasKey(arg):
      result.add(HandlerParam(
        name: arg, paramType: annotations[arg].str, reserved: arg in @["HttpRequest", "WebSocket"]
      ))
    else:
      result.add(HandlerParam(
        name: arg, paramType: "any", reserved: arg in @["HttpRequest", "WebSocket"]
      ))


proc newAnnotations*(data: PyObject): JsonNode =
  result = newJObject()
  for key in data.keys():
    result[$key] = newJString($data[$key].getAttr("__name__"))


proc initRoute*(path, purePath: string, httpMethod: seq[string], pattern: Regex2, handler: PyObject): Route =
  result = Route(
    path: path,
    purePath: purePath,
    httpMethod: httpMethod,
    pattern: pattern,
    handler: handler,
    posArgs: @[]
  )
  result.locals = pyDict()
  result.locals["handler"] = handler
  # fetch __defaults__
  if not handler.isNil:
    var defaults: JsonNode
    var argcount = handler.getAttr("__code__").getAttr("co_argcount").to(int)
    var varnames = handler.getAttr("__code__").getAttr("co_varnames").to(seq[string])
    pyValueToNim(privateRawPyObj(handler.getAttr("__defaults__")), defaults)
    # fetch pos only arguments
    for i in 0..<(argcount - defaults.len):
      result.posArgs.add(varnames[i])
    # fetch handler params with __defaults__ and __annotations__
    result.handlerParams = newHandlerParams(
      result.posArgs,
      newAnnotations(result.handler.getAttr("__annotations__"))
    )

proc hasHttpMethod*(self: Route, httpMethod: string | seq[string] | openarray[string]): bool =
  when httpMethod is string:
    return self.httpMethod.contains(httpMethod)
  else:
    for i in httpMethod:
      if self.httpMethod.contains(i):
        return true
    return false

proc initHttpRequest*(path, httpMethod: string, headers: HttpHeaders, body: string = ""): HttpRequest =
  HttpRequest(path: path, httpMethod: httpMethod, headers: headers.toPPyObject(), body: body)


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


proc hasHttpRequest*(params: seq[HandlerParam]): bool =
  for param in params:
    if param.paramType.toLower() == "httprequest":
      return true
  false
