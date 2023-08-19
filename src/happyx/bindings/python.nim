## # Python Bindings 🐍
## 
##   Provides bindings for Python programming language
## 
import
  # Stdlib
  sugar,
  tables,
  strtabs,
  strformat,
  # NimPy lib
  nimpy,
  nimpy/[py_types],
  # nimja
  nimja,
  # HappyX
  ../ssr/[server, request_models, cors],
  ../core/constants,
  ../routing/[routing],
  ./python_types


pyExportModule(name = "happyx", doc = """
HappyX web framework
""")


proc newServerPy*(address: string = "127.0.0.1", port: int = 5000): Server {.exportpy: "new_server".} =
  ## Creates a new Server object.
  newServer(address, port)


proc happyxVersion*: string {.exportpy: "happyx_version".} = HpxVersion


proc registerCORS*(allow_origins: string, allow_methods: string,
                   allow_headers: string, credentials: bool) {.exportpy: "reg_CORS".} =
  ## Registers Cross-Origins Resource Sharing at Runtime
  setCors(allow_origins, allow_methods, allow_headers, credentials)


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
  echo $pyClass
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


proc `$`*(self: Server): string {.exportpy: "__str__".} =
  fmt"Server at http://{self.address}:{self.port}/"


proc startServerPy*(self: Server) {.exportpy: "start".} =
  let py = pyBuiltinsModule()
  serve(self.address, self.port):
    discard


proc get*(self: Server, path: string): auto {.exportpy.} =
  proc wrapper(callback: PyObject) =
    let routeData = handleRoute(path)
    self.routes.add(initRoute(routeData.path, routeData.purePath, "GET", re("^" & routeData.purePath & "$"), callback))
  wrapper


proc post*(self: Server, path: string): auto {.exportpy.} =
  proc wrapper(callback: PyObject) =
    let routeData = handleRoute(path)
    self.routes.add(initRoute(routeData.path, routeData.purePath, "POST", re("^" & routeData.purePath & "$"), callback))
  wrapper


proc put*(self: Server, path: string): auto {.exportpy.} =
  proc wrapper(callback: PyObject) =
    let routeData = handleRoute(path)
    self.routes.add(initRoute(routeData.path, routeData.purePath, "PUT", re("^" & routeData.purePath & "$"), callback))
  wrapper


proc delete*(self: Server, path: string): auto {.exportpy.} =
  proc wrapper(callback: PyObject) =
    let routeData = handleRoute(path)
    self.routes.add(initRoute(routeData.path, routeData.purePath, "DELETE", re("^" & routeData.purePath & "$"), callback))
  wrapper


proc link*(self: Server, path: string): auto {.exportpy.} =
  proc wrapper(callback: PyObject) =
    let routeData = handleRoute(path)
    self.routes.add(initRoute(routeData.path, routeData.purePath, "LINK", re("^" & routeData.purePath & "$"), callback))
  wrapper


proc unlink*(self: Server, path: string): auto {.exportpy.} =
  proc wrapper(callback: PyObject) =
    let routeData = handleRoute(path)
    self.routes.add(initRoute(routeData.path, routeData.purePath, "UNLINK", re("^" & routeData.purePath & "$"), callback))
  wrapper


proc purge*(self: Server, path: string): auto {.exportpy.} =
  proc wrapper(callback: PyObject) =
    let routeData = handleRoute(path)
    self.routes.add(initRoute(routeData.path, routeData.purePath, "PURGE", re("^" & routeData.purePath & "$"), callback))
  wrapper


proc options*(self: Server, path: string): auto {.exportpy.} =
  proc wrapper(callback: PyObject) =
    let routeData = handleRoute(path)
    self.routes.add(initRoute(routeData.path, routeData.purePath, "OPTIONS", re("^" & routeData.purePath & "$"), callback))
  wrapper


proc head*(self: Server, path: string): auto {.exportpy.} =
  proc wrapper(callback: PyObject) =
    let routeData = handleRoute(path)
    self.routes.add(initRoute(routeData.path, routeData.purePath, "HEAD", re("^" & routeData.purePath & "$"), callback))
  wrapper


proc copy*(self: Server, path: string): auto {.exportpy.} =
  proc wrapper(callback: PyObject) =
    let routeData = handleRoute(path)
    self.routes.add(initRoute(routeData.path, routeData.purePath, "COPY", re("^" & routeData.purePath & "$"), callback))
  wrapper


proc middleware*(self: Server): auto {.exportpy.} =
  proc wrapper(callback: PyObject) =
    self.routes.add(initRoute("", "", "MIDDLEWARE", re("^$"), callback))
  wrapper


proc notfound*(self: Server): auto {.exportpy.} =
  proc wrapper(callback: PyObject) =
    self.routes.add(initRoute("", "", "NOTFOUND", re("^$"), callback))
  wrapper


proc mount*(self: Server, path: string, other: Server) {.exportpy.} =
  other.path = path
  self.mounts.add(other)


proc `static`*(self: Server, path: string, directory: string) {.exportpy: "static".} =
  var
    p = path
  if not p.endsWith("/"):
    p &= "/"
  p &= "{file:path}"
  let routeData = handleRoute(p)
  self.routes.add(initRoute(p, directory, "STATICFILE", re("^" & routeData.purePath & "$"), nil))