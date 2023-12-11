## # Python Bindings 🐍
## 
##   Provides bindings for Python programming language
## 
import
  # Stdlib
  sugar,
  tables,
  strtabs,
  sequtils,
  strformat,
  # NimPy lib
  nimpy,
  nimpy/[py_types],
  # nimja
  nimja,
  # HappyX
  ../ssr/[server, cors],
  ../core/[constants, exceptions, queries],
  ../routing/[routing],
  ./python_types


pyExportModule(name = "happyx", doc = """
HappyX web framework
""")


var
  servers* = newTable[int, Server]()
  serverUniqueId* = 0


proc newServerPy*(address: string = "127.0.0.1", port: int = 5000): int {.exportpy: "new_server".} =
  ## Creates a new Server object.
  ## 
  ## Arguments:
  ## - address: string = "127.0.0.1"
  ## - port: int = 5000
  inc serverUniqueId
  servers[serverUniqueId] = newServer(address, port)
  serverUniqueId


proc deleteServerPy*(serverId: int) {.exportpy: "delete_server".} =
  ## Deletes server instance
  servers.del(serverId)


proc happyxVersion*: string {.exportpy: "happyx_version".} =
  ## Returns current HappyX version
  HpxVersion


proc registerCORS*(allow_origins: string, allow_methods: string,
                   allow_headers: string, credentials: bool) {.exportpy: "reg_CORS".} =
  ## Registers Cross-Origins Resource Sharing at Runtime
  setCors(allow_origins, allow_methods, allow_headers, credentials)


proc close*(self: python_types.WebSocket) {.exportpy.} =
  self.ws.close()


proc receiveText*(self: python_types.WebSocket): string {.exportpy: "receive_text".} =
  ## Receives raw text data from WebSocket
  self.data


proc receiveJson*(self: python_types.WebSocket): JsonNode {.exportpy: "receive_json".} =
  ## Receives JSON data from WebSocket
  parseJson(self.data)


proc sendText*(self: python_types.WebSocket, value: string) {.exportpy: "send_text".} =
  ## Sends raw text to WebSocket connection
  waitFor self.ws.send(value)


proc sendJson*(self: python_types.WebSocket, value: JsonNode) {.exportpy: "send_json".} =
  ## Sends JSON to WebSocket connection
  waitFor self.ws.send($value)


proc id*(self: python_types.WebSocket): uint64 {.exportpy.} =
  ## Returns current WebSocket unique ID.
  self.id


proc state*(self: python_types.WebSocket): string {.exportpy.} =
  ## Returns current WebSocket state.
  ## 
  ## "connect" - WebSocket connection was created. Can send data. Can't receive data.
  ## "open" - WebSocket connection is opened. Can send/receive data.
  ## "close" - WebSocket connectin os closed. Can't send/receive data.
  ## "mismatch_protocol" - WebSocket Mismatch Protocol Error. Can't send/receive data.
  ## "handshake_error" - WebSocket Handshake Error (no Sec-WebSocket-Version in headers). Can't send/receive data.
  ## "error" - any other WebSocket error. Can't send/receive data.
  case self.state
  of wssConnect: "connect"
  of wssOpen: "open"
  of wssClose: "close"
  of wssHandshakeError: "handshake_error"
  of wssMismatchProtocol: "mismatch_protocol"
  of wssError: "error"


proc `==`*(self, other: python_types.WebSocket): bool {.exportpy: "__eq__".} =
  self.id == other.id


proc newResponse*(data: string, status_code: int = 200, headers: PyObject = pyDict()): ResponseObj {.exportpy: "Response".} =
  ## Raw response object
  ResponseObj(data: data, statusCode: status_code, headers: headers)
proc newFileResponse*(filename: string, status_code: int = 200, as_attachment: bool = false): FileResponseObj {.exportpy: "FileResponse".} =
  ## FileResponse object
  FileResponseObj(filename: filename, statusCode: status_code, asAttachment: asAttachment)
proc newJsonResponse*(data: JsonNode, status_code: int = 200, headers: PyObject = pyDict()): JsonResponseObj {.exportpy: "JsonResponse".} =
  ## JSON Response object
  JsonResponseObj(data: data, statusCode: status_code, headers: headers)
proc newHtmlResponse*(data: string, status_code: int = 200, headers: PyObject = pyDict()): HtmlResponseObj {.exportpy: "HtmlResponse".} =
  ## HTML Response object
  HtmlResponseObj(data: data, statusCode: status_code, headers: headers)


proc newRequestModelData*(name: string, pyClass: PyObject, fields: seq[tuple[key, val: string]]): RequestModelData {.exportpy: "RequestModelData".} =
  RequestModelData(name: name, fields: fields, pyClass: pyClass)


proc addRequestModelData*(data: RequestModelData) {.exportpy: "register_request_model_data".} =
  requestModelsHidden.requestModels.add(data)


proc path*(self: HttpRequest): string {.exportpy.} = self.path
proc body*(self: HttpRequest): string {.exportpy.} = self.body
proc httpMethod*(self: HttpRequest): string {.exportpy: "http_method".} = self.httpMethod
proc headers*(self: HttpRequest): PPyObject {.exportpy.} = self.headers

proc filename*(self: FileResponseObj): string {.exportpy.} = self.filename
proc asAttachment*(self: FileResponseObj): bool {.exportpy: "as_attachment".} = self.asAttachment

proc data*(self: ResponseObj): string {.exportpy.} = self.data
proc data*(self: JsonResponseObj): JsonNode {.exportpy.} = self.data
proc data*(self: HtmlResponseObj): string {.exportpy.} = self.data

proc statusCode*(self: ResponseObj): int {.exportpy: "status_code".} = self.statusCode
proc statusCode*(self: FileResponseObj): int {.exportpy: "status_code".} = self.statusCode
proc statusCode*(self: JsonResponseObj): int {.exportpy: "status_code".} = self.statusCode
proc statusCode*(self: HtmlResponseObj): int {.exportpy: "status_code".} = self.statusCode

proc headers*(self: ResponseObj): PyObject {.exportpy.} = self.headers
proc headers*(self: JsonResponseObj): PyObject {.exportpy.} = self.headers
proc headers*(self: HtmlResponseObj): PyObject {.exportpy.} = self.headers


proc registerRouteParamType*(name, pattern: string): auto {.exportpy: "register_route_param_type".} =
  proc hiddenHandler(callback: PyObject): PyObject =
    registerRouteParamTypeAux(name, pattern, callback)
    callback
  hiddenHandler


proc path*(serverId: int): string {.exportpy: "server_path".} =
  var
    p = ""
    s = servers[serverId]
  # Get root server
  while not s.parent.isNil():
    p = s.path & p
    s = s.parent
  return p


proc startServerPy*(serverId: int) {.exportpy: "start_server_by_id".} =
  ## Starts a new HappyX server
  ## 
  ## Server shouldn't be mounted
  {.gcsafe.}:
    var self = servers[serverId]
    if not self.parent.isNil():
      raise newException(
        HpxAppRouteDefect, fmt"Server that you start shouldn't be mounted!"
      )
  let
    py = pyBuiltinsModule()
  serve(self.address, self.port):
    discard


proc inspectCallback(callback: PyObject) {.inline.} =
  ## Raises exception if callback is coroutine
  let inspect = pyImport("inspect")
  if inspect.iscoroutinefunction(callback).to(bool):
    # Get function info
    let
      functionName = callback.getAttr("__code__").getAttr("co_name")
      filename = callback.getAttr("__code__").getAttr("co_filename")
      firstLine = callback.getAttr("__code__").getAttr("co_firstlineno")
      hash = callObject(callback.getAttr("__hash__")).to(int64)
    raise newException(
      HpxAppRouteDefect,
      fmt"""Callback function should be sync!
Async function <{functionName} at 0x{toHex(hash, 15)}> at {filename}:{firstLine}"""
    )


proc sortRoutes(self: Server) {.inline.} =
  ## Sorts routes:
  ## Firstly middlewares, secondary is routes and after notfounds 
  var
    middlewares: seq[Route] = @[]
    routes: seq[Route] = @[]
    notfounds: seq[Route] = @[]
  for i in self.routes:
    if i.httpMethod == @["MIDDLEWARE"]:
      middlewares.add(i)
    elif i.httpMethod == @["NOTFOUND"]:
      notfounds.add(i)
    else:
      routes.add(i)
  self.routes = middlewares
  for i in routes:
    self.routes.add(i)
  for i in notfounds:
    self.routes.add(i)


proc addRoute(self: Server, path: string, httpMethods: seq[string], callback: PyObject) {.inline.} =
  var
    p = path
    s = self
  # Get root server
  while not s.parent.isNil():
    p = s.path & p
    s = s.parent
  let routeData = handleRoute(p)
  s.routes.add(initRoute(routeData.path, routeData.purePath, httpMethods, re2("^" & routeData.purePath & "$"), callback))
  s.sortRoutes()


proc route*(serverId: int, path: string, methods: seq[string], callback: PyObject): auto {.exportpy: "route_server".} =
  ## Registers a new route.
  ## 
  ## You can choose HTTP methods via route("/", ["GET", "POST"])
  var self = servers[serverId]
  inspectCallback(callback)
  var httpMethods = methods
  for i in 0..<httpMethods.len:
    httpMethods[i] = httpMethods[i].toUpper()
  self.addRoute(path, httpMethods, callback)


proc get*(serverId: int, path: string, callback: PyObject): auto {.exportpy: "get_server".} =
  ## Registers a new GET route.
  var self = servers[serverId]
  inspectCallback(callback)
  self.addRoute(path, @["GET"], callback)


proc post*(serverId: int, path: string, callback: PyObject): auto {.exportpy: "post_server".} =
  ## Registers a new POST route.
  var self = servers[serverId]
  inspectCallback(callback)
  self.addRoute(path, @["POST"], callback)


proc put*(serverId: int, path: string, callback: PyObject): auto {.exportpy: "put_server".} =
  ## Registers a new PUT route.
  var self = servers[serverId]
  inspectCallback(callback)
  self.addRoute(path, @["PUT"], callback)


proc delete*(serverId: int, path: string, callback: PyObject): auto {.exportpy: "delete_server".} =
  ## Registers a new DELETE route.
  var self = servers[serverId]
  inspectCallback(callback)
  self.addRoute(path, @["DELETE"], callback)


proc link*(serverId: int, path: string, callback: PyObject): auto {.exportpy: "link_server".} =
  ## Registers a new LINK route.
  var self = servers[serverId]
  inspectCallback(callback)
  self.addRoute(path, @["LINK"], callback)


proc unlink*(serverId: int, path: string, callback: PyObject): auto {.exportpy: "unlink_server".} =
  ## Registers a new UNLINK route.
  var self = servers[serverId]
  inspectCallback(callback)
  self.addRoute(path, @["UNLINK"], callback)


proc purge*(serverId: int, path: string, callback: PyObject): auto {.exportpy: "purge_server".} =
  ## Registers a new PURGE route.
  var self = servers[serverId]
  inspectCallback(callback)
  self.addRoute(path, @["PURGE"], callback)


proc options*(serverId: int, path: string, callback: PyObject): auto {.exportpy: "options_server".} =
  ## Registers a new OPTIONS route.
  var self = servers[serverId]
  inspectCallback(callback)
  self.addRoute(path, @["OPTIONS"], callback)


proc head*(serverId: int, path: string, callback: PyObject): auto {.exportpy: "head_server".} =
  ## Registers a new HEAD route.
  var self = servers[serverId]
  inspectCallback(callback)
  self.addRoute(path, @["HEAD"], callback)


proc copy*(serverId: int, path: string, callback: PyObject): auto {.exportpy: "copy_server".} =
  ## Registers a new COPY route.
  var self = servers[serverId]
  inspectCallback(callback)
  self.addRoute(path, @["COPY"], callback)


proc websocket*(serverId: int, path: string, callback: PyObject): auto {.exportpy: "websocket_server".} =
  ## Registers a new WEBSOCKET route.
  var self = servers[serverId]
  inspectCallback(callback)
  self.addRoute(path, @["WEBSOCKET"], callback)


proc middleware*(serverId: int, callback: PyObject): auto {.exportpy: "middleware_server".} =
  ## Registers a new MIDDLEWARE route.
  var self = servers[serverId]
  inspectCallback(callback)
  self.addRoute("", @["MIDDLEWARE"], callback)


proc notfound*(serverId: int, callback: PyObject): auto {.exportpy: "notfound_server".} =
  ## Registers a new NOT FOUND route.
  var self = servers[serverId]
  inspectCallback(callback)
  self.addRoute("", @["NOTFOUND"], callback)


proc mount*(serverId: int, path: string, otherId: int) {.exportpy: "mount_server".} =
  ## Registers sub application at `path`
  servers[otherId].path = path
  servers[otherId].parent = servers[serverId]
  # Get root server
  var
    self = servers[serverId]
    other = servers[otherId]
  for route in other.routes:
    self.addRoute(path & route.purePath, route.httpMethod, route.handler)


proc `static`*(serverId: int, path: string, directory: string, extensions: seq[string]) {.exportpy: "static_server".} =
  ## Registers public folder
  var
    p = path
    s = servers[serverId]
  while not s.parent.isNil():
    p = s.path & p
    s = s.parent
  if not p.endsWith("/"):
    p &= "/"
  p &= "{file:path}"
  let routeData = handleRoute(p)
  s.routes.add(
    initRoute(p, directory, @["STATICFILE"].concat(extensions), re2("^" & routeData.purePath & "$"), nil)
  )
