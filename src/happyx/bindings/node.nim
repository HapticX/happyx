import denim except `%*`
import
  nimja,
  sugar,
  tables,
  ../core/[constants, queries],
  ../routing/[routing, mounting],
  ../ssr/[server, request_models, session, utils],
  ./node_types


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


proc addRoute(self: Server, path: string, httpMethods: seq[string], callback: string, docs: string) {.inline.} =
  var
    p = path
    s = self
  # Get root server
  while not s.parent.isNil():
    p = s.path & p
    s = s.parent
  let routeData = handleRoute(p)
  var route = initRoute(routeData.path, routeData.purePath, httpMethods, re2("^" & routeData.purePath & "$"), callback, docs)
  s.routes.add(route)
  s.sortRoutes()


proc requestAnswer(req: Request, data: string, code: HttpCode, headers: HttpHeaders) {. async .} =
  req.answer(data, code, headers)


template generateAndSaveCallback(httpMethod: string): untyped =
  ## Some boilerplate for create callbacks
  var self = servers[args.get("serverId").getInt]
  let funcUniqName = "jsCallbackFunc" & `httpMethod` & "_" & genSessionId()
  self.addRoute(args.get("path").getStr, @[`httpMethod`], funcUniqName, args.get("docs").getStr)
  setProperty(getGlobal(), funcUniqName, args.get("callback"))


init proc(module: Module) =
  # Constants
  var hpxVersion {.export_napi.} = HpxVersion


  # Server functions
  proc hpxServer(address: string, port: int, title: string): int {.export_napi.} =
    ## Creates a new Server object and returns its ID in servers array to work with it
    var self = newServer(args.get("address").getStr, args.get("port").getInt)
    servers.add(self)
    self.title = args.get("title").getStr
    # Return Server index
    return jsObj(servers.len - 1)
  
  
  proc hpxServerRoute(serverId: int, methods: napi_object, path: string, callback: napi_function, docs: string): void {.export_napi.} =
    ## Creates a new route
    var self = servers[args.get("serverId").getInt]
    # Generate unique ID for JavaScript callback function
    if args.get("methods").isArray():
      var methodsSeq: seq[string] = @[]
      for m in args.get("methods").items():
        if m.kind == napi_string:
          methodsSeq.add(m.getStr.toUpper())
      let funcUniqName = "jsCallbackFuncROUTE_" & genSessionId()
      self.addRoute(args.get("path").getStr, methodsSeq, funcUniqName, args.get("docs").getStr)
      # Save JavaScript callback function into global scope
      setProperty(getGlobal(), funcUniqName, args.get("callback"))
  

  proc hpxServerGet(serverId: int, path: string, callback: napi_function, docs: string): void {.export_napi.} =
    ## Creates a new GET route
    generateAndSaveCallback("GET")
  
  proc hpxServerPost(serverId: int, path: string, callback: napi_function, docs: string): void {.export_napi.} =
    ## Creates a new POST route
    generateAndSaveCallback("POST")
  
  proc hpxServerLink(serverId: int, path: string, callback: napi_function, docs: string): void {.export_napi.} =
    ## Creates a new LINK route
    generateAndSaveCallback("LINK")
  
  proc hpxServerPurge(serverId: int, path: string, callback: napi_function, docs: string): void {.export_napi.} =
    ## Creates a new PURGE route
    generateAndSaveCallback("PURGE")
  
  proc hpxServerTrace(serverId: int, path: string, callback: napi_function, docs: string): void {.export_napi.} =
    ## Creates a new TRACE route
    generateAndSaveCallback("TRACE")
  
  proc hpxServerOptions(serverId: int, path: string, callback: napi_function, docs: string): void {.export_napi.} =
    ## Creates a new OPTIONS route
    generateAndSaveCallback("OPTIONS")
  
  proc hpxServerPatch(serverId: int, path: string, callback: napi_function, docs: string): void {.export_napi.} =
    ## Creates a new PATCH route
    generateAndSaveCallback("PATCH")
  
  proc hpxServerPut(serverId: int, path: string, callback: napi_function, docs: string): void {.export_napi.} =
    ## Creates a new PUT route
    generateAndSaveCallback("PUT")

  proc hpxServerDelete(serverId: int, path: string, callback: napi_function, docs: string): void {.export_napi.} =
    ## Creates a new DELETE route
    generateAndSaveCallback("DELETE")
  
  proc hpxServerHead(serverId: int, path: string, callback: napi_function, docs: string): void {.export_napi.} =
    ## Creates a new HEAD route
    generateAndSaveCallback("HEAD")
  
  proc hpxServerCopy(serverId: int, path: string, callback: napi_function, docs: string): void {.export_napi.} =
    ## Creates a new COPY route
    generateAndSaveCallback("COPY")
  

  proc hpxServerWebSocket(serverId: int, path: string, callback: napi_function): void {.export_napi.} =
    ## Creates a new WEBSOCKET route
    var self = servers[args.get("serverId").getInt]
    let funcUniqName = "jsCallbackFuncWEBSOCKET_" & genSessionId()
    self.addRoute("", @["WEBSOCKET"], funcUniqName, "")
    setProperty(getGlobal(), funcUniqName, args.get("callback"))

  proc hpxServerMiddleware(serverId: int, callback: napi_function): void {.export_napi.} =
    ## Creates a new middleware route
    var self = servers[args.get("serverId").getInt]
    let funcUniqName = "jsCallbackFuncMiddleware_" & genSessionId()
    self.addRoute("", @["MIDDLEWARE"], funcUniqName, "")
    setProperty(getGlobal(), funcUniqName, args.get("callback"))
  

  proc hpxServerNotFound(serverId: int, callback: napi_function): void {.export_napi.} =
    ## Creates a new not found route
    var self = servers[args.get("serverId").getInt]
    let funcUniqName = "jsCallbackFuncNotFound_" & genSessionId()
    self.addRoute("", @["NOTFOUND"], funcUniqName, "")
    setProperty(getGlobal(), funcUniqName, args.get("callback"))


  proc hpxServerMount(serverId: int, path: string, otherServerId: int): void {.export_napi.} =
    ## Registers sub application at `path`
    var
      self: Server = servers[args.get("serverId").getInt]
      other: Server = servers[args.get("otherServerId").getInt]
    other.path = args.get("path").getStr
    other.parent = self


  proc hpxServerStatic(serverId: int, path: string, directory: string) {.export_napi.} =
    ## Registers public folder
    var
      p = args.get("path").getStr
      s = servers[args.get("serverId").getInt]
    while not s.parent.isNil():
      p = s.path & p
      s = s.parent
    if not p.endsWith("/"):
      p &= "/"
    p &= "{file:path}"
    let routeData = handleRoute(p)
    s.routes.add(initRoute(p, args.get("directory").getStr, @["STATICFILE"], re2("^" & routeData.purePath & "$"), "", ""))
  

  proc hpxStartServer(serverId: int): void {. export_napi .} =
    ## Stars server by it's ID in servers array
    # Load server from servers list
    var self: Server = servers[args.get("serverId").getInt]
    # Register routes
    serve self.address, self.port:
      discard
  

  # Work with WebSockets
  proc hpxWebSocketClose(websocketId: string): void {. export_napi .} =
    ## Close websocket connection
    wsClients[args.get("websocketId").getStr].ws.close()
    unregisterWsClient(args.get("websocketId").getStr)
  
  proc hpxWebSocketSendText(websocketId: string, data: string): void {. export_napi .} =
    ## Sends TEXT to websocket if available.
    asyncCheck wsClients[args.get("websocketId").getStr].ws.send(args.get("data").getStr)
  
  proc hpxWebSocketSendJson(websocketId: string, data: napi_object): void {. export_napi .} =
    ## Sends JSON to websocket if available.
    asyncCheck wsClients[args.get("websocketId").getStr].ws.send(
      napiCall("JSON.stringify", [args.get("data")]).getStr
    )
  

  # Work with requests
  proc hpxRequestAnswerStr(reqId: string, data: string, httpCode: int, headers: napi_object): void {. export_napi .} =
    var req = requests[args.get("reqId").getStr]
    asyncCheck req.requestAnswer(
      args.get("data").getStr, HttpCode(args.get("httpCode").getInt),
      args.get("headers").toHttpHeaders
    )
  
  proc hpxRequestAnswerInt(reqId: string, data: int, httpCode: int, headers: napi_object): void {. export_napi .} =
    var req = requests[args.get("reqId").getStr]
    asyncCheck req.requestAnswer(
      $args.get("data").getInt, HttpCode(args.get("httpCode").getInt),
      args.get("headers").toHttpHeaders
    )
  
  proc hpxRequestAnswerBool(reqId: string, data: bool, httpCode: int, headers: napi_object): void {. export_napi .} =
    var req = requests[args.get("reqId").getStr]
    asyncCheck req.requestAnswer(
      $args.get("data").getBool, HttpCode(args.get("httpCode").getInt),
      args.get("headers").toHttpHeaders
    )
  
  proc hpxRequestAnswerObj(reqId: string, data: napi_object, httpCode: int, headers: napi_object): void {. export_napi .} =
    var req = requests[args.get("reqId").getStr]
    asyncCheck req.requestAnswer(
      $args.get("data"), HttpCode(args.get("httpCode").getInt),
      args.get("headers").toHttpHeaders
    )
  

  proc hpxRegisterRequestModel(name: string, data: napi_object) {. export_napi .} =
    ## Adds a new Request Model
    var fields: seq[tuple[key, val: string]] = @[]
    for k, v in args.get("data").pairs():
      fields.add((key: k, val: v.getStr))
    requestModelsHidden.requestModels.add(RequestModelData(
      name: args.get("name").getStr,
      fields: fields
    ))
  

  proc hpxRegisterPathParamType(name: string, pattern: string, callback: napi_function) {. export_napi .} =
    let funcUniqName = "jsCallbackFuncCustomPathParam_" & genSessionId()
    registerRouteParamTypeAux(
      args.get("name").getStr,
      args.get("pattern").getStr,
      funcUniqName
    )
    setProperty(getGlobal(), funcUniqName, args.get("callback"))
