## # Server 🔨
## 
## Provides a Server object that encapsulates the server's address, port, and logger.
## Developers can customize the logger's format using the built-in newConsoleLogger function.
## HappyX provides two options for handling HTTP requests: httpx, microasynchttpserver and asynchttpserver.
## 
## 
## To enable httpx just compile with `-d:httpx` or `-d:happyxHttpx`.
## To enable MicroAsyncHttpServer just compile with `-d:micro` or `-d:happyxMicro`.
## To enable HttpBeast just compile with `-d:beast` or `-d:happyxBeast`
## 
## To enable debugging just compile with `-d:happyxDebug`.
## 
## ## Queries ❔
## In any request you can get queries.
## 
## Just use `query~name` to get any query param. By default returns `""`
## 
## If you want to use [arrays in query](https://github.com/HapticX/happyx/issues/101) just use
## `queryArr~name` to get any array query param.
## 
## ## WebSockets 🍍
## In any request you can get connected websocket clients.
## Just use `wsConnections` that type is `seq[WebSocket]`
## 
## In any websocket route you can use `wsClient` for working with current websocket client.
## `wsClient` type is `WebSocket`.
## 
## 
## ## Static directories 🍍
## To declare static directory you just should mark it as static directory 🙂
## 
## .. code-block:: nim
##    serve(...):
##      # Users can get all files in /myDirectory via
##      # http://.../myDirectory/path/to/file
##      staticDir "myDirectory"
## 
## ### Custom static directory ⚙
## To declare custom path for static dir just use this
## 
## .. code-block:: nim
##    serve(...):
##      # Users can get all files in /myDirectory via
##      # http://.../customPath/path/to/file
##      staticDir "/customPath" -> "myDirectory"
## 
## > Note: here you can't use path params
## 

import
  # Stdlib
  std/asyncdispatch,
  std/strformat,
  std/asyncfile,
  std/segfaults,
  std/mimetypes,
  std/strutils,
  std/terminal,
  std/strtabs,
  std/logging,
  std/cookies,
  std/macros,
  std/macrocache,
  std/tables,
  std/colors,
  std/json,
  std/os,
  std/exitprocs,
  # Deps
  regex,
  # HappyX
  ./cors,
  ../spa/[tag, renderer, translatable],
  ../core/[exceptions, constants, queries],
  ../private/[macro_utils],
  ../routing/[routing, mounting],
  ../sugar/sgr

export
  strutils,
  strtabs,
  strformat,
  asyncdispatch,
  asyncfile,
  logging,
  cookies,
  colors,
  regex,
  json,
  terminal,
  os


when enableHttpx:
  import
    options,
    httpx
  export
    options,
    httpx
elif enableHttpBeast:
  import httpbeast, asyncnet
  export httpbeast, asyncnet
elif enableMicro:
  import microasynchttpserver, asynchttpserver
  export microasynchttpserver, asynchttpserver
else:
  import asynchttpserver
  export asynchttpserver


when enableHttpBeast:
  import websocket
  export websocket
else:
  import websocketx
  export websocketx


when enableApiDoc:
  import
    nimja,
    ./request_models,
    ../private/api_doc_template


type CustomHeaders* = StringTableRef

proc newCustomHeaders*: CustomHeaders = newStringTable().CustomHeaders

proc `[]=`*[T](self: CustomHeaders, key: string, value: T) =
  when not (T is string):
    self[key] = $value
  else:
    self[key] = value


when exportPython or defined(docgen):
  import
    nimpy,
    ../bindings/python_types
  
  pyExportModule(name = "server", doc = """
HappyX web framework [SSR/SSG Part]
""")

  type
    Server* = ref object of PyNimObjectExperimental
      address*: string
      port*: int
      routes*: seq[Route]
      path*: string
      parent*: Server
      notFoundCallback*: PyObject
      middlewareCallback*: PyObject
      logger*: Logger
      when enableHttpx:
        instance*: Settings
      elif enableHttpBeast:
        instance*: Settings
      elif enableMicro:
        instance*: MicroAsyncHttpServer
      else:
        instance*: AsyncHttpServer
      components: TableRef[string, BaseComponent]
    ModelBase* = ref object of PyNimObjectExperimental
elif defined(napibuild):
  import denim except `%*`
  import../bindings/node_types

  type
    Server* = ref object
      address*: string
      port*: int
      logger*: Logger
      path*: string
      parent*: Server
      routes*: seq[Route]
      title*: string
      environment*: napi_env
      when enableHttpx:
        instance*: Settings
      elif enableHttpBeast:
        instance*: Settings
      elif enableMicro:
        instance*: MicroAsyncHttpServer
      else:
        instance*: AsyncHttpServer
      components: TableRef[string, BaseComponent]
    ModelBase* = object of RootObj
else:
  type
    Server* = object
      address*: string
      port*: int
      logger*: Logger
      when enableHttpx:
        instance*: Settings
      elif enableHttpBeast:
        instance*: Settings
      elif enableMicro:
        instance*: MicroAsyncHttpServer
      else:
        instance*: AsyncHttpServer
      components: TableRef[string, BaseComponent]
    ModelBase* = object of RootObj


when enableApiDoc:
  type
    ApiDocObject* = object
      description*: string
      path*: string
      httpMethod*: seq[string]
      pathParams*: seq[PathParamObj]
      models*: seq[RequestModelObj]
    
  proc newApiDocObject*(httpMethod: seq[string], description, path: string, pathParams: seq[PathParamObj],
                        models: seq[RequestModelObj]): ApiDocObject =
    ApiDocObject(httpMethod: httpMethod, description: description, path: path,
                 pathParams: pathParams, models: models)


var
  pointerServer: ptr Server
  loggerCreated: bool = false
const liveViews = CacheSeq"HappyXLiveViews"


when defined(napibuild):
  import ./session

  var
    servers*: seq[Server] = @[]
    requests* = newTable[string, Request]()
    wsClients* = newTable[string, node_types.WebSocket]()
  
  proc registerWsClient*(wsClient: node_types.WebSocket): string {.gcsafe.} =
    {.gcsafe.}:
      result = genSessionId()
      wsClients[result] = wsClient
  
  proc unregisterWsClient*(wsClientId: string) {.gcsafe.} =
    {.gcsafe.}:
      wsClients.del(wsClientId)
  
  proc registerRequest*(req: Request): string {.gcsafe.} =
    {.gcsafe.}:
      result = genSessionId()
      requests[result] = req
  
  proc unregisterRequest*(reqId: string) {.gcsafe.} =
    {.gcsafe.}:
      requests.del(reqId)
else:
  proc ctrlCHook() {.noconv.} =
    quit(QuitSuccess)

  proc onQuit() {.noconv.} =
    when int(enableHttpBeast) + int(enableHttpx) + int(enableMicro) == 0:
      try:
        pointerServer[].instance.close()
      except:
        discard

  when not defined(docgen) and not nim_2_0_0:
    setControlCHook(ctrlCHook)
    addExitProc(onQuit)


func fgColored*(text: string, clr: ForegroundColor): string {.inline.} =
  ## This function takes in a string of text and a ForegroundColor enum
  ## value and returns the same text with the specified color applied.
  ## 
  ## Arguments:
  ## - `text`: A string value representing the text to apply color to.
  ## - `clr`: A ForegroundColor enum value representing the color to apply to the text.
  ## 
  ## Return value:
  ## - The function returns a string value with the specified color applied to the input text.
  runnableExamples:
    echo fgColored("Hello, world!", fgRed)
  ansiForegroundColorCode(clr) & text & ansiResetCode


proc newServer*(address: string = "127.0.0.1", port: int = 5000): Server =
  ## This procedure creates and returns a new instance of the `Server` object,
  ## which listens for incoming connections on the specified IP address and port.
  ## If no address is provided, it defaults to `127.0.0.1`,
  ## which is the local loopback address.
  ## If no port is provided, it defaults to `5000`.
  ## 
  ## Parameters:
  ## - `address` (optional): A string representing the IP address that the server should listen on.
  ##   Defaults to `"127.0.0.1"`.
  ## - `port` (optional): An integer representing the port number that the server should listen on.
  ## 
  ## Returns:
  ## - A new instance of the `Server` object.
  runnableExamples:
    var s = newServer()
    assert s.address == "127.0.0.1"
  {.cast(gcsafe).}:
    result = Server(
      address: address,
      port: port,
      components: newTable[string, BaseComponent](),
      logger:
        if loggerCreated:
          newConsoleLogger(lvlNone, fgColored("[$date at $time]:$levelname ", fgYellow))
        else:
          loggerCreated = true
          newConsoleLogger(lvlInfo, fgColored("[$date at $time]:$levelname ", fgYellow))
    )
  when enableHttpx or enableHttpBeast:
    result.instance = initSettings(Port(port), bindAddr=address, numThreads = numThreads)
  elif enableMicro:
    result.instance = newMicroAsyncHttpServer()
  else:
    result.instance = newAsyncHttpServer()
  pointerServer = addr result
  addHandler(result.logger)


template start*(server: Server): untyped =
  ## The `start` template starts the given server and listens for incoming connections.
  ## Parameters:
  ## - `server`: A `Server` instance that needs to be started.
  ## 
  ## Returns:
  ## - `untyped`: This template does not return any value.
  when enableDebug:
    info "Server started at http://" & `server`.address & ":" & $`server`.port
  when not declared(handleRequest):
    proc handleRequest(req: Request) {.async.} =
      discard
  when enableHttpx:
    run(handleRequest, `server`.instance)
  elif enableHttpBeast:
    {.cast(gcsafe).}:
      run(handleRequest, `server`.instance)
  else:
    waitFor `server`.instance.serve(Port(`server`.port), handleRequest, `server`.address)


{.experimental: "dotOperators".}
macro `.`*(obj: JsonNode, field: untyped): JsonNode =
  newCall("[]", obj, newLit($field.toStrLit))


template answer*(
    req: Request,
    message: string,
    code: HttpCode = Http200,
    headers: HttpHeaders = newHttpHeaders([
      ("Content-Type", "text/plain; charset=utf-8")
    ])
) =
  ## Answers to the request
  ## 
  ## ⚠ `Low-level API` ⚠
  ## 
  ## Arguments:
  ##   `req: Request`: An instance of the Request type, representing the request that we are responding to.
  ##   `message: string`: The message that we want to include in the response body.
  ##   `code: HttpCode = Http200`: The HTTP status code that we want to send in the response.
  ##                               This argument is optional, with a default value of Http200 (OK).
  ## 
  ## Use this example instead
  ## 
  ## .. code-block::nim
  ##    get "/":
  ##      return "Hello, world!"
  ## 
  var h = headers
  addCORSHeaders(h)
  when declaredInScope(outHeaders):
    for key, val in outHeaders.pairs():
      h[key] = val
  when enableHttpx or enableHttpBeast:
    var headersArr: seq[string] = @[]
    for key, value in h.pairs():
      headersArr.add(key & ':' & value)
    when declaredInScope(cookies):
      for cookie in cookies:
        headersArr.add(cookie)
    when declaredInScope(statusCode):
      req.send(statusCode.HttpCode, message, headersArr.join("\r\n"))
    else:
      req.send(code, message, headersArr.join("\r\n"))
  else:
    when declaredInScope(cookies):
      for cookie in cookies:
        let data = cookie.split(":", 1)
        h.add("Set-Cookie", data[1].strip())
    when declaredInScope(statusCode):
      await req.respond(statusCode.HttpCode, message, h)
    else:
      await req.respond(code, message, h)


when enableHttpBeast:
  proc send*(ws: AsyncWebSocket, data: string) {.async.} =
    await ws.sendText(data)


template answerJson*(req: Request, data: untyped, code: HttpCode = Http200,
                     headers: HttpHeaders = newHttpHeaders([("Content-Type", "application/json; charset=utf-8")])): untyped =
  ## Answers to request with json data
  ## 
  ## ⚠ `Low-level API` ⚠
  ## 
  ## Use this example instead
  ## 
  ## .. code-block::nim
  ##    var json = %*{"response": 1}
  ##    
  ##    get "/1":
  ##      # respond variable
  ##      return json
  ##    get "/2":
  ##      # respond JSON directly
  ##      return {"response": 1}
  ## 
  answer(req, $(%*`data`), code, headers)


template answerHtml*(req: Request, data: string | TagRef, code: HttpCode = Http200,
                     headers: HttpHeaders = newHttpHeaders([("Content-Type", "text/html; charset=utf-8")])): untyped =
  ## Answers to request with HTML data
  ## 
  ## ⚠ `Low-level API` ⚠
  ## 
  ## Use this example instead:
  ##
  ## .. code-block::nim
  ##    var html = buildHtml:
  ##      tDiv:
  ##        "Hello, world!"
  ##    
  ##    get "/1":
  ##      # Respond HTML variable
  ##      return html
  ##    get "/2":
  ##      # Respond HTML directly
  ##      return buildHtml:
  ##        tDiv:
  ##          "Hello, world!"
  ## 
  when data is string:
    let d = data
  else:
    let d = $data
  answer(req, d, code, headers)


proc answerFile*(req: Request, filename: string,
                 code: HttpCode = Http200, asAttachment = false) {.async.} =
  ## Respond file to request.
  ## 
  ## ⚠ `Low-level API` ⚠
  ## 
  ## Use this example instead of this procedure
  ## 
  ## .. code-block::nim
  ##    get "/$filename":
  ##      return FileResponse("/publicFolder" / filename)
  ## 
  let
    splitted = filename.split('.')
    extension = if splitted.len > 1: splitted[^1] else: ""
    contentType = newMimetypes().getMimetype(extension)
  var f = openAsync(filename, fmRead)
  let content = await f.readAll()
  f.close()
  var headers = @[("Content-Type", fmt"{contentType}; charset=utf-8")]
  if asAttachment:
    headers.add(("Content-Disposition", "attachment"))
  req.answer(content, headers = newHttpHeaders(headers))


proc detectReturnStmt(node: NimNode, replaceReturn: bool = false) =
  # Replaces all `return` statements with req answer*
  for i in 0..<node.len:
    var child = node[i]
    if child.kind == nnkReturnStmt and child[0].kind != nnkEmpty:
      # HTML
      if child[0].kind == nnkCall and child[0][0].kind == nnkIdent and $child[0][0] == "buildHtml":
        node[i] = newCall("answerHtml", ident"req", child[0])
      # File
      elif child[0].kind in nnkCallKinds and child[0][0].kind == nnkIdent and $child[0][0] == "FileResponse":
        node[i] = newCall("await", newCall("answerFile", ident"req", child[0][1]))
      # JSON
      elif child[0].kind in [nnkTableConstr, nnkBracket]:
        node[i] = newCall("answerJson", ident"req", child[0])
      # Any string
      elif child[0].kind in [nnkStrLit, nnkTripleStrLit]:
        when enableAutoTranslate:
          node[i] = newCall("answer", ident"req", formatNode(newCall("translate", child[0])))
        else:
          node[i] = newCall("answer", ident"req", formatNode(child[0]))
      elif child[0].kind in {nnkCharLit..nnkFloat128Lit}:
        node[i] = newCall("answer", ident"req", newLit($child[0].toStrLit))
      # Variable
      else:
        when enableAutoTranslate:
          node[i] = newNimNode(nnkWhenStmt).add(
            newNimNode(nnkElifBranch).add(
              newCall("is", child[0], ident"JsonNode"),
              newCall("answerJson", ident"req", child[0])
            ),
            newNimNode(nnkElifBranch).add(
              newCall("is", child[0], ident"TagRef"),
              newCall("answerHtml", ident"req", child[0])
            ),
            newNimNode(nnkElse).add(
              newCall("answer", ident"req", newCall("translate", child[0]))
            )
          )
        else:
          node[i] = newNimNode(nnkWhenStmt).add(
            newNimNode(nnkElifBranch).add(
              newCall("is", child[0], ident"JsonNode"),
              newCall("answerJson", ident"req", child[0])
            ),
            newNimNode(nnkElifBranch).add(
              newCall("is", child[0], ident"TagRef"),
              newCall("answerHtml", ident"req", child[0])
            ),
            newNimNode(nnkElse).add(
              newCall("answer", ident"req", child[0])
            )
          )
    else:
      node[i].detectReturnStmt(true)
  # Replace last node
  if replaceReturn or node.kind in AtomicNodes:
    return
  if node[^1].kind in [nnkCall, nnkCommand]:
    if node[^1][0].kind == nnkIdent and re2"^(answer|echo|translate)" in $node[^1][0]:
      return
    elif node[^1][0].kind == nnkDotExpr and ($node[^1][0][1]).toLower().startsWith("answer"):
      return
  if not node[^1].isExpr:
    return
  if node[^1].kind == nnkCall and $node[^1][0] == "buildHtml":
    node[^1] = newCall("answerHtml", ident"req", node[^1])
  elif node[^1].kind == nnkTableConstr:
    node[^1] = newCall("answerJson", ident"req", node[^1])
  elif node[^1].kind in [nnkStrLit, nnkTripleStrLit]:
    when enableAutoTranslate:
      node[^1] = newCall("answer", ident"req", formatNode(newCall("translate", node[^1])))
    else:
      node[^1] = newCall("answer", ident"req", formatNode(node[^1]))
  else:
    when enableAutoTranslate:
      node[^1] = newCall("answer", ident"req", newCall("translate", node[^1]))
    else:
      node[^1] = newCall("answer", ident"req", node[^1])


macro routes*(server: Server, body: untyped = newStmtList()): untyped =
  ## You can create routes with this marco
  ## 
  ## #### Available Path Params
  ## - `bool`: any boolean (`y`, `yes`, `on`, `1` and `true` for true; `n`, `no`, `off`, `0` and `false` for false).
  ## - `int`: any integer.
  ## - `float`: any float number.
  ## - `word`: any word includes `re2"\w+"`.
  ## - `string`: any string excludes `"/"`.
  ## - `enum(EnumName)`: any string excludes `"/"`. Converts into `EnumName`.
  ## - `path`: any float number includes `"/"`.
  ## - `regex`: any regex pattern excludes groups. Usage - `"/path{pattern:/yourRegex/}"`
  ## 
  ## #### Available Route Types
  ## - `"/path/with/{args:path}"`: Just string with route path. Matches any request method
  ## - `get "/path/{args:word}"`: Route with request method. Method can be`get`, `post`, `patch`, etc.
  ## - `notfound`: Route that matches when no other matched.
  ## - `middleware`: Always executes first.
  ## - `finalize`: Executes when server is closing
  ## 
  ## #### Route Scope:
  ## - `req`: Current request
  ## - `urlPath`: Current url path
  ## - `query`: Current url path queries
  ## - `queryArr`: Current url path queries (usable for seq[string])
  ## - `wsConnections`: All websocket connections
  ## 
  ## #### Available Websocket Routing
  ## - `ws "/path/to/websockets/{args:word}`: Route with websockets
  ## - `wsConnect`: Calls on any websocket client was connected
  ## - `wsClosed`: Calls on any websocket client was disconnected
  ## - `wsMismatchProtocol`: Calls on mismatch protocol
  ## - `wsError`: Calls on any other ws error
  ## 
  ## #### Websocket Scope:
  ## - `req`: Current request
  ## - `urlPath`: Current url path
  ## - `query`: Current url path queries
  ## - `queryArr`: Current url path queries (usable for seq[string])
  ## - `wsClient`: Current websocket client
  ## - `wsConnections`: All websocket connections
  ## 
  ## # Example
  ## 
  ## .. code-block:: nim
  ##    var myServer = newServer()
  ##    myServer.routes:
  ##      "/":
  ##        "root"
  ##      "/user{id:int}":
  ##        "hello, user {id}!"
  ##      middleware:
  ##        echo req
  ##      notfound:
  ##        "Oops! Not found!"
  let
    pathIdent = ident"urlPath"
  var
    # Handle requests
    body = body
    stmtList = newStmtList()
    ifStmt = newNimNode(nnkIfStmt)
    notFoundNode = newEmptyNode()
    wsNewConnection = newStmtList()
    wsClosedConnection = newStmtList()
    wsMismatchProtocol = newStmtList()
    variables = newStmtList()
    wsError = newStmtList()
    procStmt = newProc(
      ident"handleRequest",
      [newEmptyNode(), newIdentDefs(ident"req", ident"Request")],
      stmtList
    )
    caseRequestMethodsStmt = newNimNode(nnkCaseStmt)
    methodTable = newTable[string, NimNode]()
    finalize = newStmtList()
  
  for liveView in liveViews:
    let
      path = liveView[0]
      statement = liveView[1]
      connection = newNimNode(nnkCurly).add(newCall(
        "&",
        newCall(
          "&",
          newCall(
            "&",
            newCall(
              "&",
              newCall(
                "&",
                newLit("var socketToSsr = new WebSocket(\"ws://"),
                newDotExpr(ident"server", ident"address"),
              ),
              newLit":",
            ),
            newCall("$", newDotExpr(ident"server", ident"port"))
          ),
          path
        ),
        newLit("\")")
      ))
      getMethod = quote do:
        {.gcsafe.}:
          var html = buildHtml:
            tHead:
              tTitle: "SSR Components are here!"
              tScript(src = "https://cdn.tailwindcss.com")
            tBody:
              tDiv(id = "app"): `statement`
              tDiv(id = "scripts")
            tScript: `connection`
            tScript: """
const x=document.getElementById("scripts");
const a=document.getElementById("app");
socketToSsr.onmessage=function(m){
  const res=JSON.parse(m.data);switch(res.action){
    case"script":x.innerHTML="";const e1=document.createRange().createContextualFragment(res.data);x.append(e1);break;case"html":const e2=document.createRange().createContextualFragment(res.data);a.append(e2);break;case"route":window.location.replace(res.data);break;default:break}};
  function isObjLiteral(_o) {
    var _t = _o;
    return typeof _o !== "object" || _o === null ? false : function () {
      while (!false) {
        if (Object.getPrototypeOf(_t = Object.getPrototypeOf(_t)) === null) {break;}
      }
      return Object.getPrototypeOf(_o) === _t;
    }()
  }

  function complex(e) {
    const i=typeof e === "function";
    const j=typeof e === "object" && !isObjLiteral(e);
    return i||j;
  }

  function se(e, x) {
    const r = {};
    for (const k in e) {
      if (!e[k]) {continue;}
      if (typeof e[k] !== "function" && typeof e[k] !== "object") {
        r[k] = e[k];
      } else if (!(r[k] in x) && x.length < 2 && e[k] !== "function") {
        r[k] = se(e[k], x.concat([e[k]]));
      }
    }
    return r;
  }
  
  function callEventHandler(i, e) {
    let ev = se(e,[e]);
    ev['eventName'] = ev.constructor.name;
    socketToSsr.send(JSON.stringify({
      "action": "callEventHandler",
      "idx": i,
      "event": ev
    }));
  }
  function callComponentEventHandler(c, i, e) {
    let ev = se(e, [e]);
    ev['eventName'] = ev.constructor.name;
    socketToSsr.send(JSON.stringify({
      "action": "callComponentEventHandler",
      "idx": i,
      "event": ev,
      "componentId": c
    }));
  }
"""
        return html
      wsMethod = quote do:
        ws `path`:
          var parsed = parseJson(wsData)
          {.gcsafe.}:
            case parsed["action"].getStr
            of "callComponentEventHandler":
              let comp = components[parsed["componentId"].getStr]
              componentEventHandlers[parsed["idx"].getInt](comp, parsed["event"])
              if componentsResult.hasKey(comp.uniqCompId):
                await wsClient.send($componentsResult[comp.uniqCompId])
                componentsResult.del(comp.uniqCompId)
            of "callEventHandler":
              eventHandlers[parsed["idx"].getInt](parsed["event"])
              when enableHttpBeast or enableHttpx:
                let hostname = req.ip
                if requestResult.hasKey(hostname):
                  await wsClient.send($requestResult[hostname])
                  requestResult.del(hostname)
              else:
                if requestResult.hasKey(req.hostname):
                  await wsClient.send($requestResult[req.hostname])
                  requestResult.del(req.hostname)
    body.add(wsMethod)
    body.add(newCall(ident"get", path, getMethod))

  when enableHttpx or enableHttpBeast:
    var path = newNimNode(nnkBracketExpr).add(
      newCall("split", newCall("get", newCall("path", ident"req")), newStrLitNode("?")),
      newIntLitNode(0)
    )
    let
      requestBody = newCall("get", newDotExpr(ident"req", ident"body"))
      reqMethod = newCall("get", newDotExpr(ident"req", ident"httpMethod"))
      hostname = newDotExpr(ident"req", ident"ip")
      headers = newCall("get", newDotExpr(ident"req", ident"headers"))
      acceptLanguage = newNimNode(nnkBracketExpr).add(
        newCall(
          "split", newNimNode(nnkBracketExpr).add(headers, newStrLitNode("accept-language")), newLit(',')
        ), newLit(0)
      )
      val = ident(fmt"_val")
      url = newStmtList(
        newLetStmt(val, newCall("split", newCall("get", newCall("path", ident"req")), newStrLitNode("?"))),
        newNimNode(nnkIfStmt).add(
          newNimNode(nnkElifBranch).add(
            newCall(">=", newCall("len", val), newIntLitNode(2)),
            newNimNode(nnkBracketExpr).add(val, newIntLitNode(1))
          ), newNimNode(nnkElse).add(
            newStrLitNode("")
          )
        )
      )
  else:
    var path = newDotExpr(newDotExpr(ident"req", ident"url"), ident"path")
    let
      reqMethod = newDotExpr(ident"req", ident"reqMethod")
      hostname = newDotExpr(ident"req", ident"hostname")
      headers = newDotExpr(ident"req", ident"headers")
      requestBody = newDotExpr(ident"req", ident"body")
      acceptLanguage = newNimNode(nnkBracketExpr).add(
        newCall(
          "split", newNimNode(nnkBracketExpr).add(headers, newStrLitNode("accept-language")), newLit(',')
        ), newLit(0)
      )
      url = newDotExpr(newDotExpr(ident"req", ident"url"), ident"query")
  let
    directoryFromPath = newCall(
      "&",
      newStrLitNode("."),
      newCall("replace", pathIdent, newLit('/'), ident"DirSep")
    )
    cookiesOutVar = newCall(newNimNode(nnkBracketExpr).add(ident"newSeq", ident"string"))
    cookiesInVar = newNimNode(nnkIfStmt).add(
      newNimNode(nnkElifBranch).add(
        newCall("hasKey", headers, newStrLitNode("cookie")),
        newCall("parseCookies", newCall("$", newNimNode(nnkBracketExpr).add(headers, newStrLitNode("cookie"))))
      ), newNimNode(nnkElse).add(
        newCall("parseCookies", newStrLitNode(""))
      )
    )
    isWebsocketConnection =
      newCall(
        "and",
        newCall(
          "and",
          newCall("hasKey", headers, newStrLitNode("connection")),
          newCall("hasKey", headers, newStrLitNode("upgrade")),
        ),
        newCall(
          "and",
          newCall("contains", newCall("[]", headers, newStrLitNode("connection")), newStrLitNode("upgrade")),
          newCall("==", newCall("toLower", newCall("[]", headers, newStrLitNode("upgrade"), newLit(0))), newStrLitNode("websocket")),
        )
      )
  
  when defined(debug):
    caseRequestMethodsStmt.add(ident"reqMethod")
  else:
    caseRequestMethodsStmt.add(reqMethod)
  
  procStmt.addPragma(ident"async")

  # Find mounts
  body.findAndReplaceMount()

  for key, val in sugarRoutes.pairs():
    if ($val[0]).toLower() == "any":
      body.add(newCall(newStrLitNode(key), val[1]))
    elif ($val[0]).toLower() in httpMethods:
      body.add(newNimNode(nnkCommand).add(
        val[0],
        newStrLitNode(key),
        val[1]
      ))
  
  for statement in body:
    if statement.kind == nnkDiscardStmt:
      continue
    if statement.kind in [nnkCall, nnkCommand]:
      if statement[^1].kind == nnkStmtList:
        # Check variable usage
        if statement[^1].isIdentUsed(ident"statusCode"):
          statement[^1].insert(0, newVarStmt(ident"statusCode", newLit(200)))
        if statement[^1].isIdentUsed(ident"outHeaders"):
          statement[^1].insert(0, newVarStmt(ident"outHeaders", newCall("newCustomHeaders")))
        if statement[^1].isIdentUsed(ident"cookies") or statement[^1].isIdentUsed(ident"startSession"):
          statement[^1].insert(0, newVarStmt(ident"cookies", cookiesOutVar))
      # "/...": statement list
      if statement[1].kind == nnkStmtList and statement[0].kind == nnkStrLit:
        detectReturnStmt(statement[1])
        let exported = exportRouteArgs(pathIdent, statement[0], statement[1])
        if exported.len > 0:  # /my/path/with{custom:int}/{param:path}
          ifStmt.add(exported)
        else:  # /just-my-path
          ifStmt.add(newNimNode(nnkElifBranch).add(
            newCall("==", pathIdent, statement[0]), statement[1]
          ))
      # [get, post, ...] "/...": statement list
      elif statement.len == 3 and statement[2].kind == nnkStmtList and statement[0].kind == nnkBracket and statement[1].kind == nnkStrLit and statement[0].len > 0:
        detectReturnStmt(statement[2])
        let exported = exportRouteArgs(pathIdent, statement[1], statement[2])
        var methods = newNimNode(nnkBracket)
        for i in statement[0]:
          methods.add(newLit(($i).toLower()))
        if exported.len > 0:  # /my/path/with{custom:int}/{param:path}
          exported[0] = newCall(
            "and",
            newCall("contains", methods, newCall("toLower", newCall("$", reqMethod))),
            exported[0].copy()
          )
          ifStmt.add(exported)
        else:  # /just-my-path
          ifStmt.add(newNimNode(nnkElifBranch).add(
            newCall(
              "and",
              newCall("contains", methods, newCall("toLower", newCall("$", reqMethod))),
              newCall("==", pathIdent, statement[1])
            ), statement[2]
          ))
      # reqMethod "/...":
      #   ...
      elif statement[0].kind == nnkIdent and statement[0] != ident"mount" and statement[1].kind in {nnkStrLit, nnkTripleStrLit, nnkInfix}:
        let name = ($statement[0]).toUpper()
        if name == "STATICDIR":
          if statement[1].kind in [nnkStrLit, nnkTripleStrLit]:
            ifStmt.insert(
              0, newNimNode(nnkElifBranch).add(
                newCall(
                  "and",
                  newCall(
                    "or",
                    newCall("startsWith", pathIdent, statement[1]),
                    newCall("startsWith", pathIdent, newStrLitNode("/" & $statement[1])),
                  ), newCall(
                    "fileExists",
                    directoryFromPath
                  )
                ),
                newStmtList(
                  newCall("await", newCall("answerFile", ident"req", directoryFromPath))
                )
              )
            )
          else:
            let
              route = if $statement[1][1] == "/": newStrLitNode("") else: statement[1][1]
              path = if $statement[1][1] == "/": newStrLitNode($statement[1][2] & "/") else: statement[1][2]
            let dirFromPath = newCall(
              "&",
              newCall("&", newStrLitNode("."), newLit("/")),
              newCall(
                "replace",
                newCall("replace", pathIdent, statement[1][1], path),
                newLit('/'), ident"DirSep"
              )
            )
            ifStmt.insert(
              0, newNimNode(nnkElifBranch).add(
                newCall(
                  "and",
                  newCall("startsWith", pathIdent, route),
                  newCall("fileExists", dirFromPath)
                ),
                newStmtList(
                  newCall("await", newCall("answerFile", ident"req", dirFromPath))
                )
              )
            )
          continue
        let exported = exportRouteArgs(pathIdent, statement[1], statement[2])
        # Handle websockets
        if name == "WS":
          var
            insertWsList = newStmtList()
            wsDelStmt = newStmtList(
              newCall(
                "del",
                ident"wsConnections",
                newCall("find", ident"wsConnections", ident"wsClient"))
            )
          when enableHttpx:
            wsDelStmt.add(
              newCall("close", ident"wsClient")
            )
          when enableHttpBeast:
            let asyncFd = newDotExpr(newDotExpr(ident"req", ident"client"), ident"AsyncFD")
            let wsStmtList = newStmtList(
              newLetStmt(
                ident"headers",
                newCall("get", newDotExpr(ident"req", ident"headers"))
              ),
              newCall("forget", ident"req"),
              newCall("register", asyncFd),
              newLetStmt(ident"socket", newCall("newAsyncSocket", asyncFd)),
              newMultiVarStmt(
                [ident"wsClient", ident"error"],
                newCall("await", newCall("verifyWebsocketRequest", ident"socket", ident"headers", newLit(""))),
                true
              ),
              newNimNode(nnkIfStmt).add(newNimNode(nnkElifBranch).add(
                newCall("isNil", ident"wsClient"),
                newStmtList(
                  newCall("close", ident"socket")
                )
              ), newNimNode(nnkElse).add(newStmtList(
                newCall("add", ident"wsConnections", ident"wsClient"),
                wsNewConnection,
                newNimNode(nnkWhileStmt).add(newLit(true), newStmtList(
                  newMultiVarStmt(
                    [ident"opcode", ident"wsData"],
                    newCall("await", newCall("readData", ident"wsClient")),
                    true
                  ),
                  newNimNode(nnkTryStmt).add(
                    # TRY
                    newStmtList(
                      newNimNode(nnkIfStmt).add(newNimNode(nnkElifBranch).add(
                        newCall("==", ident"opcode", newDotExpr(ident"Opcode", ident"Close")),
                        newStmtList(
                          when enableDebug:
                            newStmtList(
                              newCall("error", newStrLitNode("Socket closed")),
                              wsDelStmt,
                              wsClosedConnection
                            )
                          else:
                            if wsClosedConnection.len == 0:
                              wsDelStmt
                            else:
                              wsClosedConnection.add(wsDelStmt),
                          newNimNode(nnkBreakStmt).add(newEmptyNode())
                        )
                      )),
                      insertWsList
                    # OTHER WS ERROR
                    ), newNimNode(nnkExceptBranch).add(
                      when enableDebug:
                        newStmtList(
                          newCall(
                            "error",
                            newCall("fmt", newStrLitNode("Unexpected socket error: {getCurrentExceptionMsg()}"))
                          ),
                          wsDelStmt,
                          wsError
                        )
                      else:
                        if wsError.len == 0:
                          wsDelStmt
                        else:
                          wsError.add(wsDelStmt)
                    )
                  )
                ))
              ))),
            )
          else:
            let wsStmtList = newStmtList(
              newLetStmt(ident"wsClient", newCall("await", newCall("newWebSocket", ident"req"))),
              newCall("add", ident"wsConnections", ident"wsClient"),
              newNimNode(nnkTryStmt).add(
                newStmtList(
                  wsNewConnection,
                  newNimNode(nnkWhileStmt).add(
                    newCall("==", newDotExpr(ident"wsClient", ident"readyState"), ident"Open"),
                    newStmtList(
                      newLetStmt(ident"wsData", newCall("await", newCall("receiveStrPacket", ident"wsClient"))),
                      insertWsList
                    )
                  )
                ),
                newNimNode(nnkExceptBranch).add(
                  ident"WebSocketClosedError",
                  when enableDebug:
                    newStmtList(
                      newCall(
                        "error", newCall("fmt", newStrLitNode("Socket closed: {getCurrentExceptionMsg()}"))
                      ),
                      wsDelStmt,
                      wsClosedConnection
                    )
                  else:
                    if wsClosedConnection.len == 0:
                      wsDelStmt
                    else:
                      wsClosedConnection.add(wsDelStmt)
                ),
                newNimNode(nnkExceptBranch).add(
                  ident"WebSocketProtocolMismatchError",
                  when enableDebug:
                    newStmtList(
                      newCall(
                        "error",
                        newCall("fmt", newStrLitNode("Socket tried to use an unknown protocol: {getCurrentExceptionMsg()}"))
                      ),
                      wsDelStmt,
                      wsMismatchProtocol
                    )
                  else:
                    if wsMismatchProtocol.len == 0:
                      wsDelStmt
                    else:
                      wsMismatchProtocol.add(wsDelStmt)
                ),
                newNimNode(nnkExceptBranch).add(
                  ident"WebSocketError",
                  when enableDebug:
                    newStmtList(
                      newCall(
                        "error",
                        newCall("fmt", newStrLitNode("Unexpected socket error: {getCurrentExceptionMsg()}"))
                      ),
                      wsDelStmt,
                      wsError
                    )
                  else:
                    if wsError.len == 0:
                      wsDelStmt
                    else:
                      wsError.add(wsDelStmt)
                )
              )
            )
          if not methodTable.hasKey("GET"):
            methodTable["GET"] = newNimNode(nnkIfStmt)
          if exported.len > 0:
            insertWsList.add(exported[1])
            exported[1].add(wsStmtList)
            methodTable["GET"].add(exported)
          else:
            insertWsList.add(statement[2])
            methodTable["GET"].add(newNimNode(nnkElifBranch).add(
              newCall("and", isWebsocketConnection, newCall("==", pathIdent, statement[1])),
              wsStmtList
            ))
          continue
        let methodName = $name
        if not methodTable.hasKey(methodName):
          methodTable[methodName] = newNimNode(nnkIfStmt)
        if exported.len > 0:  # /my/path/with{custom:int}/{param:path}
          detectReturnStmt(exported[1])
          methodTable[methodName].add(exported)
        else:  # /just-my-path
          detectReturnStmt(statement[2])
          methodTable[methodName].add(newNimNode(nnkElifBranch).add(
            newCall("==", pathIdent, statement[1]),
            statement[2]
          ))
      # notfound: statement list
      elif statement[1].kind == nnkStmtList and statement[0].kind == nnkIdent:
        case ($statement[0]).toLower()
        of "wsconnect":
          wsNewConnection = statement[1]
        of "wsclosed":
          wsClosedConnection = statement[1]
        of "wsmismatchprotocol":
          wsMismatchProtocol = statement[1]
        of "wserror":
          wsError = statement[1]
        of "finalize":
          finalize = statement[1]
        of "notfound":
          detectReturnStmt(statement[1])
          notFoundNode = statement[1]
        of "middleware":
          detectReturnStmt(statement[1])
          stmtList.insert(0, statement[1])
        else:
          throwDefect(
            HpxServeRouteDefect,
            "Wrong serve route detected ",
            lineInfoObj(statement[0])
          )
    elif statement.kind in [nnkVarSection, nnkLetSection]:
      variables.add(statement)
  
  let
    immutableVars = newNimNode(nnkLetSection).add(
      newIdentDefs(ident"urlPath", newEmptyNode(), path),
    )
    mutableVars = newNimNode(nnkVarSection)

  # immutable variables
  stmtList.insert(0, immutableVars)
  stmtList.insert(0, mutableVars)
  
  when enableDebug:
    stmtList.add(newCall(
      "info",
      newCall("fmt", newStrLitNode("{reqMethod}::{urlPath}"))
    ))
  
  stmtList.add(caseRequestMethodsStmt)
  for key in methodTable.keys():
    caseRequestMethodsStmt.add(newNimNode(nnkOfBranch).add(
      newLit(parseEnum[HttpMethod](key)),
      methodTable[key]
    ))
  # NodeJS Library
  when defined(napibuild):
    stmtList.add(newCall("handleNodeRequest", ident"self", ident"req", ident"urlPath"))
  # Python Library
  elif exportPython or defined(docgen):
    stmtList.add(newVarStmt(ident"reqResponded", newLit(false)))
    stmtList.add(newNimNode(nnkForStmt).add(
      ident"route", newDotExpr(ident"self", ident"routes"),
      newNimNode(nnkIfStmt).add(newNimNode(nnkElifBranch).add(
        newCall(
          "or",
          newCall(
            "and",
            newCall(
              "==",
              newCall("@", bracket(newLit"NOTFOUND")),
              newDotExpr(ident"route", ident"httpMethod")
            ),
            newCall("not", ident"reqResponded")
          ),
          newCall(
            "or",
            newCall(
              "==",
              newCall("@", bracket(newLit"MIDDLEWARE")),
              newDotExpr(ident"route", ident"httpMethod")
            ),
            newCall(
              "or",
              newCall(
                "and",
                newCall("contains", newDotExpr(ident"route", ident"httpMethod"), newCall("$", reqMethod)),
                newCall("contains", pathIdent, newDotExpr(ident"route", ident"pattern"))
              ),
              newCall(
                "and",
                newCall(
                  "hasHttpMethod",
                  ident"route",
                  newCall("@", bracket(newLit"STATICFILE", newLit"WEBSOCKET"))
                ),
                newCall("contains", pathIdent, newDotExpr(ident"route", ident"pattern"))
              ),
            )
          ),
        ),
        newNimNode(nnkPragmaBlock).add(
          newNimNode(nnkPragma).add(newNimNode(nnkCast).add(
            newEmptyNode(), ident"gcsafe"
          )),
          newStmtList(
            newNimNode(nnkIfStmt).add(newNimNode(nnkElifBranch).add(
              newCall(
                "!=",
                newCall("@", bracket(newLit"MIDDLEWARE")),
                newDotExpr(ident"route", ident"httpMethod")
              ),
              newAssignment(ident"reqResponded", newLit(true))
            )),
            # Declare HttpRequest
            newVarStmt(
              ident"request",
              newCall(
                "initHttpRequest", path, newCall("$", reqMethod), headers, requestBody
              )
            ),
            newNimNode(nnkIfStmt).add(newNimNode(nnkElifBranch).add(
              newCall(
                "==",
                newCall("@", bracket(newLit"STATICFILE")),
                newDotExpr(ident"route", ident"httpMethod")
              ),
              newStmtList(
                # Declare RouteData
                newVarStmt(ident"routeData", newCall("handleRoute", newDotExpr(ident"route", ident"path"))),
                # Unpack route path params
                newLetStmt(
                  ident"founded_regexp_matches",
                  newCall("findAll", pathIdent, newDotExpr(ident"route", ident"pattern"))
                ),
                # Load path params into function parameters
                newLetStmt(ident"funcParams", newCall(
                  "getRouteParams", ident"routeData", ident"founded_regexp_matches",
                  pathIdent, newNimNode(nnkExprEqExpr).add(
                    ident"force", newLit(true)
                  )
                )),
                newCall(
                  "await",
                  newCall(
                    "answerFile",
                    ident"req",
                    newCall(
                      "&",
                      newDotExpr(ident"route", ident"purePath"),
                      newCall("$", newCall("[]", ident"funcParams", newLit"file"))
                    )
                  )
                ),
                newNimNode(nnkReturnStmt).add(newEmptyNode()),
              )
            ), newNimNode(nnkElse).add(newStmtList(
              # Detect queries
              newLetStmt(ident"queryFromUrl", url),
              newLetStmt(ident"query", newCall("parseQuery", ident"queryFromUrl")),
              # Declare RouteData
              newVarStmt(ident"routeData", newCall("handleRoute", newDotExpr(ident"route", ident"path"))),
              # Declare route handler
              newVarStmt(ident"handler", newDotExpr(ident"route", ident"handler")),
              # Declare Python Locals (for eval func)
              newVarStmt(ident"locals", newCall("pyDict")),
              # Declare Python Object (for function params)
              newNimNode(nnkVarSection).add(newIdentDefs(ident"pyFuncParams", ident"PyObject")),
              newNimNode(nnkVarSection).add(newIdentDefs(ident"pyNone", ident"PyObject")),
              # Declare JsonNode (for length of keyword arguments)
              newNimNode(nnkVarSection).add(newIdentDefs(ident"keywordArgumentss", ident"JsonNode")),
              # Include route handler into Python locals 
              newCall("[]=", ident"locals", newLit"handler", ident"handler"),
              # Unpack route path params
              newLetStmt(ident"founded_regexp_matches", newCall("findAll", pathIdent, newDotExpr(ident"route", ident"pattern"))),
              # handle callback data
              newVarStmt(ident"variables", newCall(newNimNode(nnkBracketExpr).add(ident"newSeq", ident"string"))),
              newLetStmt(ident"argcount", newCall("getAttr", newCall("getAttr", ident"handler", newLit"__code__"), newLit"co_argcount")),
              newLetStmt(ident"varnames", newCall("getAttr", newCall("getAttr", ident"handler", newLit"__code__"), newLit"co_varnames")),
              newLetStmt(ident"pDefaults", newCall("getAttr", ident"handler", newLit"__defaults__")),
              # Create Python Object
              newCall(ident"pyValueToNim", newCall("privateRawPyObj", ident"pDefaults"), ident"keywordArgumentss"),
              newLetStmt(ident"annotations", newCall("newAnnotations", newCall("getAttr", ident"handler", newLit("__annotations__")))),
              # Extract function arguments from Python
              newNimNode(nnkForStmt).add(
                ident"i",
                newCall(
                  "..<",
                  newLit(0),
                  newCall("-", newCall("to", ident"argcount", ident"int"), newCall("len", ident"keywordArgumentss"))
                ),
                newCall("add", ident"variables", newCall("to", newCall("[]", ident"varnames", ident"i"), ident"string"))
              ),
              # Match function parameters with annotations (or without)
              newLetStmt(ident"handlerParams", newCall("newHandlerParams", ident"variables", ident"annotations")),
              # Load path params into function parameters
              newLetStmt(ident"funcParams", newCall(
                "getRouteParams", ident"routeData", ident"founded_regexp_matches",
                pathIdent, ident"handlerParams", requestBody
              )),
              newLetStmt(ident"none", newCall("newPyNone")),
              newCall(ident"pyValueToNim", ident"none", ident"pyNone"),
              # Add queries to function parameters
              newNimNode(nnkForStmt).add(
                ident"param", ident"handlerParams",
                newNimNode(nnkIfStmt).add(newNimNode(nnkElifBranch).add(
                  newCall(
                    "and",
                    newCall(
                      "not",
                      newCall(
                        "!=",
                        newCall("callMethod", ident"funcParams", newLit"get", newDotExpr(ident"param", ident"name")),
                        ident"pyNone"
                      )
                    ),
                    newCall(
                      "not",
                      newCall(
                        "contains",
                        newNimNode(nnkBracket).add(newLit"HttpRequest", newLit"WebSocket"),
                        newDotExpr(ident"param", ident"paramType")
                      )
                    )
                  ),
                  newCall(
                    "[]=",
                    ident"funcParams",
                    newDotExpr(ident"param", ident"name"),
                    newNimNode(nnkCaseStmt).add(
                      newDotExpr(ident"param", ident"paramType"),
                      newNimNode(nnkOfBranch).add(
                        newLit"bool",
                        newCall(
                          "parseBoolOrJString",
                          newCall("getOrDefault", ident"query", newDotExpr(ident"param", ident"name"))
                        )
                      ),
                      newNimNode(nnkOfBranch).add(
                        newLit"int",
                        newCall(
                          "parseIntOrJString",
                          newCall("getOrDefault", ident"query", newDotExpr(ident"param", ident"name"))
                        )
                      ),
                      newNimNode(nnkOfBranch).add(
                        newLit"float",
                        newCall(
                          "parseFloatOrJString",
                          newCall("getOrDefault", ident"query", newDotExpr(ident"param", ident"name"))
                        )
                      ),
                      newNimNode(nnkElse).add(
                        newCall("newJString", newCall("getOrDefault", ident"query", newDotExpr(ident"param", ident"name")))
                      ),
                    )
                  )
                ))
              ),
              # Create Pointer to Python Object
              newLetStmt(ident"pFuncParams", newCall("nimValueToPy", ident"funcParams")),
              # Create Python Object
              newCall(ident"pyValueToNim", ident"pFuncParams", ident"pyFuncParams"),
              # Add HttpRequest to function parameters if required
              newNimNode(nnkIfStmt).add(newNimNode(nnkElifBranch).add(
                newCall("hasHttpRequest", ident"handlerParams"),
                newCall(
                  "[]=",
                  ident"pyFuncParams",
                  newCall("getParamName", ident"handlerParams", newLit"HttpRequest"),
                  ident"request"
                )
              )),
              newLetStmt(
                ident"arr",
                newCall(
                  "to",
                  newCall("callMethod", ident"py", newLit"list", newCall("callMethod", ident"funcParams", newLit"keys")),
                  ident"JsonNode"
                )
              ),
              # Detect and create classes for request models
              newNimNode(nnkForStmt).add(
                ident"param", ident"arr",
                newStmtList(
                  newLetStmt(ident"paramType", newCall("getParamType", ident"handlerParams", newCall("getStr", ident"param"))),
                  # If param is request model
                  newNimNode(nnkIfStmt).add(newNimNode(nnkElifBranch).add(
                    newCall("contains", ident"requestModelsHidden", ident"paramType"),
                    newStmtList(
                      # Get Python class
                      newVarStmt(
                        ident"requestModel",
                        newDotExpr(newCall("[]", ident"requestModelsHidden", ident"paramType"), ident"pyClass")
                      ),
                      # Create Python class instance
                      newLetStmt(
                        ident"pyClassInstance",
                        newCall(
                          "callObject",
                          newCall("getAttr", ident"requestModel", newLit"from_dict"),
                          ident"requestModel",
                          newCall("[]", ident"pyFuncParams", ident"param")
                        )
                      ),
                      newCall("[]=", ident"pyFuncParams", ident"param", ident"pyClassInstance"),
                    )
                  )),
                )
              ),
              newNimNode(nnkIfStmt).add(newNimNode(nnkElifBranch).add(
                newCall(
                  "==",
                  newCall("@", bracket(newLit"WEBSOCKET")),
                  newDotExpr(ident"route", ident"httpMethod")
                ),
                newStmtList(
                  newLetStmt(ident"wsClient", newCall("await", newCall("newWebSocket", ident"req"))),
                  # Declare route handler
                  newVarStmt(ident"handler", newDotExpr(ident"route", ident"handler")),
                  newLetStmt(ident"wsConnection", newCall("newWebSocketObj", ident"wsClient", newLit"")),
                  newNimNode(nnkIfStmt).add(newNimNode(nnkElifBranch).add(
                    newCall("hasParamType", ident"handlerParams", newLit"WebSocket"),
                    newCall(
                      "[]=",
                      ident"pyFuncParams",
                      newCall("getParamName", ident"handlerParams", newLit"WebSocket"),
                      ident"wsConnection"
                    )
                  )),
                  # Add function parameters to locals
                  newCall("[]=", ident"locals", newLit"funcParams", ident"pFuncParams"),
                  newNimNode(nnkTryStmt).add(
                    newStmtList(
                      # call connect
                      newAssignment(newDotExpr(ident"wsConnection", ident"state"), ident"wssConnect"),
                      newCall("processWebSocket", ident"py", ident"locals"),
                      newAssignment(newDotExpr(ident"wsConnection", ident"state"), ident"wssOpen"),
                      newNimNode(nnkWhileStmt).add(
                        newCall("==", newDotExpr(ident"wsClient", ident"readyState"), ident"Open"),
                        newStmtList(
                          newLetStmt(ident"wsData", newCall("await", newCall("receiveStrPacket", ident"wsClient"))),
                          newAssignment(newDotExpr(ident"wsConnection", ident"data"), ident"wsData"),
                          newCall("processWebSocket", ident"py", ident"locals"),
                        )
                      )
                    ),
                    newNimNode(nnkExceptBranch).add(
                      ident"WebSocketClosedError",
                      newStmtList(
                        newAssignment(newDotExpr(ident"wsConnection", ident"state"), ident"wssClose"),
                        newCall("processWebSocket", ident"py", ident"locals"),
                      )
                    ),
                    newNimNode(nnkExceptBranch).add(
                      ident"WebSocketHandshakeError",
                      newStmtList(
                        newCall(
                          "error",
                          newLit"Invalid WebSocket handshake. Headers haven't Sec-WebSocket-Version!"
                        ),
                        newAssignment(newDotExpr(ident"wsConnection", ident"state"), ident"wssHandshakeError"),
                        newCall("processWebSocket", ident"py", ident"locals"),
                      )
                    ),
                    newNimNode(nnkExceptBranch).add(
                      ident"WebSocketProtocolMismatchError",
                      newStmtList(
                        newCall(
                          "error",
                          newCall("fmt", newLit"Socket tried to use an unknown protocol: {getCurrentExceptionMsg()}")
                        ),
                        newAssignment(newDotExpr(ident"wsConnection", ident"state"), ident"wssMismatchProtocol"),
                        newCall("processWebSocket", ident"py", ident"locals"),
                      )
                    ),
                    newNimNode(nnkExceptBranch).add(
                      ident"WebSocketError",
                      newStmtList(
                        newCall(
                          "error",
                          newCall("fmt", newStrLitNode("Unexpected socket error: {getCurrentExceptionMsg()}"))
                        ),
                        newAssignment(newDotExpr(ident"wsConnection", ident"state"), ident"wssError"),
                        newCall("processWebSocket", ident"py", ident"locals"),
                      )
                    )
                  ),
                  newCall("close", ident"wsClient"),
                  # Break all code after this
                  newNimNode(nnkReturnStmt).add(newEmptyNode())
                )
              )),
              # Add function parameters to locals
              newCall("[]=", ident"locals", newLit"funcParams", ident"pFuncParams"),
              # Execute callback
              newLetStmt(
                ident"response",
                newCall(
                  newDotExpr(ident"py", ident"eval"),
                  newLit("handler(**funcParams)"),
                  ident"locals"
                )
              ),
              # Handle response type
              newLetStmt(
                ident"responseType",
                newCall("getAttr", newCall("getAttr", ident"response", newLit("__class__")), newLit("__name__"))
              ),
              # Respond
              newNimNode(nnkIfStmt).add(newNimNode(nnkElifBranch).add(
                newCall("!=", ident"response", newDotExpr(ident"py", ident"None")),
                newNimNode(nnkCaseStmt).add(
                  newCall("$", ident"responseType"),
                  newNimNode(nnkOfBranch).add(
                    newLit("dict"),
                    newCall("answerJson", ident"req", newCall("to", ident"response", ident"JsonNode"))
                  ),
                  newNimNode(nnkOfBranch).add(
                    newLit("JsonResponseObj"),
                    newStmtList(
                      newLetStmt(ident"resp", newCall("to", ident"response", ident"JsonResponseObj")),
                      newCall(
                        "answerJson",
                        ident"req",
                        newCall("data", ident"resp"),
                        newCall("HttpCode", newCall("statusCode", ident"resp")),
                        newCall("toHttpHeaders", newCall("headers", ident"resp"))
                      )
                    )
                  ),
                  newNimNode(nnkOfBranch).add(
                    newLit("HtmlResponseObj"),
                    newStmtList(
                      newLetStmt(ident"resp", newCall("to", ident"response", ident"HtmlResponseObj")),
                      newCall(
                        "answerHtml",
                        ident"req",
                        newCall("data", ident"resp"),
                        newCall("HttpCode", newCall("statusCode", ident"resp")),
                        newCall("toHttpHeaders", newCall("headers", ident"resp"))
                      )
                    )
                  ),
                  newNimNode(nnkOfBranch).add(
                    newLit("FileResponseObj"),
                    newStmtList(
                      newLetStmt(ident"resp", newCall("to", ident"response", ident"FileResponseObj")),
                      newCall(
                        "await",
                        newCall(
                          "answerFile",
                          ident"req",
                          newCall("filename", ident"resp"),
                          newCall("HttpCode", newCall("statusCode", ident"resp")),
                          newCall("asAttachment", ident"resp")
                        )
                      )
                    )
                  ),
                  newNimNode(nnkElse).add(
                    newCall("answer", ident"req", newCall("$", ident"response"))
                  )
                )
              )),
              ))
            ),
          ),
        )
      ))
    ))
  caseRequestMethodsStmt.add(newNimNode(nnkElse).add(newStmtList()))

  if ifStmt.len > 0:
    stmtList.add(ifStmt)
    # return 404
    if notFoundNode.kind == nnkEmpty:
      let elseStmtList = newStmtList()
      ifStmt.add(newNimNode(nnkElse).add(elseStmtList))
      when enableDebug:
        elseStmtList.add(
          newCall(
            "warn",
            newCall(
              "fgColored", 
              newCall("fmt", newStrLitNode("{urlPath} is not found.")), ident"fgYellow"
            )
          )
        )
      elseStmtList.add(
        newCall(ident"answer", ident"req", newStrLitNode("Not found"), ident"Http404")
      )
    else:
      ifStmt.add(newNimNode(nnkElse).add(notFoundNode))
  else:
    # return 404
    if notFoundNode.kind == nnkEmpty:
      # when enableDebug:
      #   stmtList.add(newCall(
      #     "warn",
      #     newCall(
      #       "fgColored",
      #       newCall("fmt", newStrLitNode("{urlPath} is not found.")), ident"fgYellow"
      #     )
      #   ))
      stmtList.add(
        newCall(ident"answer", ident"req", newStrLitNode("Not found"), ident"Http404")
      )
    else:
      stmtList.add(notFoundNode)
  result = newStmtList(
    if stmtList.isIdentUsed(ident"wsConnections"):
      newNimNode(nnkVarSection).add(newIdentDefs(
        ident"wsConnections",
        when enableHttpBeast:
          newNimNode(nnkBracketExpr).add(ident"seq", ident"AsyncWebSocket")
        else:
          newNimNode(nnkBracketExpr).add(ident"seq", ident"WebSocket"),
        newCall("@", newNimNode(nnkBracket)),
      ))
    else:
      newEmptyNode(),
    procStmt,
    newProc(
      ident"finalizeProgram",
      [newEmptyNode()],
      finalize,
      pragmas = newNimNode(nnkPragma).add(ident"noconv")
    )
  )

  for v in countdown(variables.len-1, 0, 1):
    result.insert(0, variables[v])
  
  if stmtList.isIdentUsed(ident"query"):
    immutableVars.add(newIdentDefs(ident"queryFromUrl", newEmptyNode(), url))
    immutableVars.add(newIdentDefs(ident"query", newEmptyNode(), newCall("parseQuery", ident"queryFromUrl")))
    when not exportPython and not defined(napibuild):
      immutableVars.add(newIdentDefs(ident"queryArr", newEmptyNode(), newCall("parseQueryArrays", ident"queryFromUrl")))
  if stmtList.isIdentUsed(ident"translate"):
    immutableVars.add(newIdentDefs(ident"acceptLanguage", newEmptyNode(), acceptLanguage))
  when defined(napibuild):
    immutableVars.add(newIdentDefs(ident"inCookies", newEmptyNode(), cookiesInVar))
  else:
    if stmtList.isIdentUsed(ident"inCookies"):
      immutableVars.add(newIdentDefs(ident"inCookies", newEmptyNode(), cookiesInVar))
  if stmtList.isIdentUsed(ident"reqMethod"):
    immutableVars.add(newIdentDefs(ident"reqMethod", newEmptyNode(), reqMethod))
  immutableVars.add(newIdentDefs(ident"hostname", newEmptyNode(), hostname))
  when enableDebugSsrMacro:
    echo result.toStrLit


macro initServer*(body: untyped): untyped =
  ## Shortcut for
  ## 
  ## ⚠ `Low-level API` ⚠
  ## 
  ## .. code-block:: nim
  ##    proc main() {.gcsafe.} =
  ##      `body`
  ##    main()
  ## 
  result = newStmtList(
    newProc(
      ident"main",
      [newEmptyNode()],
      body.add(
        newCall("addQuitProc", ident"finalizeProgram")
      ),
      nnkProcDef
    ),
    newCall("main")
  )
  result[0].addPragma(ident"gcsafe")
    

when enableApiDoc:
  proc fetchPathParams(route: var string): tuple[pathParams, models: NimNode] =
    var
      params = newNimNode(nnkBracket)
      models = newNimNode(nnkBracket)
      routeData = handleRoute(route)
    for i in routeData.pathParams:
      params.add(newCall(
        "newPathParamObj",
        newStrLitNode(i.name),
        newStrLitNode(i.paramType),
        newStrLitNode(i.defaultValue),
        newLit(i.optional),
        newLit(i.mutable),
      ))

    for i in routeData.requestModels:
      models.add(newCall(
        "newRequestModelObj",
        newStrLitNode(i.name),
        newStrLitNode(i.typeName),
        newStrLitNode(i.target),
        newLit(i.mutable),
      ))
    
    # Clear route
    route = routeData.path
    route = route.replace(
      re2"\{([a-zA-Z][a-zA-Z0-9_]*)\??(:(bool|int|float|string|path|word|/[\s\S]+?/|enum\(\w+\)))?(\[m\])?(=(\S+?))?\}",
      "{$1}"
    )
    route = route.replace(re2"\[([a-zA-Z][a-zA-Z0-9_]*):([a-zA-Z][a-zA-Z0-9_]*)(\[m\])?(:[a-zA-Z\\-]+)?\]", "")

    (newCall("@", params), newCall("@", models))
  

  proc fetchModelFields(): NimNode =
    var res = newNimNode(nnkTableConstr)

    for key, val in modelFields.pairs():
      var tableConstr = newNimNode(nnkTableConstr)
      for field in val:
        tableConstr.add(newNimNode(nnkExprColonExpr).add(field[0], field[1]))
      if tableConstr.len > 0:
        res.add(newNimNode(nnkExprColonExpr).add(newStrLitNode(key), newCall("newStringTable", tableConstr)))

    if res.len > 0:
      newCall("toTable", res)
    else:
      newCall(newNimNode(nnkBracketExpr).add(
        ident"initTable", ident"string", ident"StringTableRef"
      ))

  proc genApiDoc(body: var NimNode): NimNode =
    ## Returns API route
    var
      docsData = newNimNode(nnkBracket)
      bodyCopy = body.copy()
    bodyCopy.findAndReplaceMount()
    for i in bodyCopy:
      if i.kind in [nnkCall, nnkCommand]:
        if i[0].kind == nnkIdent and i.len == 3 and i[2].kind == nnkStmtList and i[1].kind == nnkStrLit:
          ## HTTP Method
          var
            description = ""
            pathParam = $i[1]
            (params, models) = fetchPathParams(pathParam)
          for statement in i[2]:
            if statement.kind == nnkCommentStmt:
              description &= $statement & "\n"
          docsData.add(newCall(
            "newApiDocObject",
            newCall("@", bracket(newLit(($i[0].toStrLit).toUpper()))),  # HTTP Method
            newLit(description),  # Description
            newLit(pathParam),  # Path
            params, models
          ))
        elif i[0].kind == nnkStrLit and i.len == 2 and i[1].kind == nnkStmtList:
          ## HTTP Method
          var
            description = ""
            pathParam = $i[0]
            (params, models) = fetchPathParams(pathParam)
          for statement in i[1]:
            if statement.kind == nnkCommentStmt:
              description &= $statement & "\n"
          docsData.add(newCall(
            "newApiDocObject",
            newCall("@", bracket(newLit"")),  # HTTP Method
            newLit(description),  # Description
            newLit(pathParam),  # Path
            params, models
          ))
        
    # Get all documentation
    body.add(newNimNode(nnkCommand).add(ident"get", newStrLitNode(
      if apiDocsPath.startsWith("/"):
        apiDocsPath
      else:
        "/" & apiDocsPath
    ), newStmtList(
      newCall("answerHtml", ident"req", newCall("renderDocsProcedure")),
    )))
    body.add(newNimNode(nnkCommand).add(ident"get", newStrLitNode(
      if apiDocsPath.startsWith("/"):
        apiDocsPath & "/openapi.json"
      else:
        "/" & apiDocsPath & "/openapi.json"
    ), newStmtList(
      newCall("answerJson", ident"req", newCall("openApiJson")),
    )))
    newCall("@", docsData)
  

  proc procApiDocs(docsData: NimNode): NimNode =
    newStmtList(
      when defined(napibuild):
        newLetStmt(ident"title", newDotExpr(ident"self", ident"title"))
      else:
        newLetStmt(ident"title", newLit(appName)),
      newNimNode(when exportPython or defined(docgen) or defined(napibuild): nnkVarSection else: nnkLetSection).add(
        newIdentDefs(
          ident"apiDocData", newNimNode(nnkBracketExpr).add(ident"seq", ident"ApiDocObject"), docsData
        )
      ),
      when exportPython or defined(docgen):
        newNimNode(nnkForStmt).add(
          ident"route", newDotExpr(ident"self", ident"routes"),
          newNimNode(nnkIfStmt).add(newNimNode(nnkElifBranch).add(
            newCall(
              "not",
              newCall(
                "hasHttpMethod",
                ident"route",
                newCall("@", bracket(newLit"MIDDLEWARE", newLit"NOTFOUND")),
              )
            ),
            newStmtList(
              # Declare RouteData
              newVarStmt(ident"routeData", newCall("handleRoute", newDotExpr(ident"route", ident"path"))),
              newNimNode(nnkIfStmt).add(
                newNimNode(nnkElifBranch).add(
                  newCall("==", newDotExpr(ident"route", ident"httpMethod"), newCall("@", bracket(newLit"STATICFILE"))),
                  newStmtList(
                    # Declare string (for documentation)
                    newVarStmt(
                      ident"documentation",
                      newCall(
                        "&",
                        newLit"Fetch file from directory: ",
                        newDotExpr(ident"route", ident"purePath")
                      )
                    ),
                    newCall("add", ident"apiDocData", newCall(
                      "newApiDocObject",
                      newCall("@", bracket(newLit"GET")),
                      ident"documentation",
                      newDotExpr(ident"routeData", ident"path"),
                      newDotExpr(ident"routeData", ident"pathParams"),
                      newDotExpr(ident"routeData", ident"requestModels"),
                    ))
                  )
                ),
                newNimNode(nnkElse).add(newStmtList(
                  # Declare route handler
                  newVarStmt(ident"handler", newDotExpr(ident"route", ident"handler")),
                  newLetStmt(ident"pDoc", newCall("getAttr", ident"handler", newLit"__doc__")),
                  # Declare string (for documentation)
                  newVarStmt(ident"documentation", newLit""),
                  # Convert __doc__ to string
                  newNimNode(nnkIfStmt).add(newNimNode(nnkElifBranch).add(
                    newCall("!=", ident"pDoc", newDotExpr(ident"py", ident"None")),
                    newCall(ident"pyValueToNim", newCall("privateRawPyObj", ident"pDoc"), ident"documentation"),
                  )),
                  newCall("add", ident"apiDocData", newCall(
                    "newApiDocObject",
                    newDotExpr(ident"route", ident"httpMethod"),
                    ident"documentation",
                    newDotExpr(ident"routeData", ident"path"),
                    newDotExpr(ident"routeData", ident"pathParams"),
                    newDotExpr(ident"routeData", ident"requestModels"),
                  ))
                ))
              )
            )),
          )
        )
      elif defined(napibuild):
        newCall("handleApiDoc", ident"self")
      else:
        newEmptyNode(),
      newNimNode(nnkLetSection).add(
        newIdentDefs(
          ident"modelsData",
          newNimNode(nnkBracketExpr).add(
            ident"Table", ident"string", ident"StringTableRef"
          ),
          fetchModelFields()
        )
      ),
    )


macro serve*(address: string, port: int, body: untyped): untyped =
  ## Initializes a new server and start it. Shortcut for
  ## 
  ## `High-level API`
  ## 
  ## .. code-block:: nim
  ##    proc main() =
  ##      var server = newServer(`address`, `port`)
  ##      server.routes:
  ##        `body`
  ##      server.start()
  ##    main()
  ## 
  ## For GC Safety you can declare your variables inside `serve` macro ✌
  ## 
  ## .. code-block:: nim
  ##    serve(...):
  ##      var index = 0
  ##      let some = "some"
  ##      
  ##      "/":
  ##        inc index
  ##        return {"index": index}
  ##      
  ##      "/some":
  ##        return some
  ## 
  var bodyStatement = body
  when enableApiDoc:
    var docsData = bodyStatement.genApiDoc()
  
  var s =
    when exportPython or defined(docgen):
      ident"self"
    else:
      ident"server"

  result = newStmtList(
    newProc(
      ident"main",
      [newEmptyNode()],
      newStmtList(
        when not exportPython:
          newVarStmt(
            ident"server",
            newCall("newServer", address, port)
          )
        else:
          newEmptyNode(),
        when enableApiDoc:
          newProc(ident"renderDocsProcedure", [ident"string"], procApiDocs(docsData).add(
            newCall("compileTemplateStr", newStrLitNode(IndexApiDocPageTemplate)),
          ))
        else:
          newEmptyNode(),
        when enableApiDoc:
          newProc(ident"openApiJson", [ident"JsonNode"], procApiDocs(docsData).add(
            quote do:
              if fileExists("openapi.json"):
                return parseFile("openapi.json")
              else:
                result = %*{
                  "openapi": "3.1.0",
                  "swagger": "2.0",
                  "info": {"title": "HappyX OpenAPI Docs", "version": "1.0.0"},
                  "paths": {}
                }
                for route in apiDocData:
                  if route.httpMethod[0] in ["MIDDLEWARE", "STATICFILE", "STATIC", "NOTFOUND"]:
                    continue
                  result["paths"][route.path] = %*{}
                  let decscription = route.description.replace(
                    re"@openapi\s*\{(\s*\w+\s*[^\n]+|\s*@(params|responses)\s*\{[^\}]+?}\s*)+\s*\}", ""
                  )
                  var pathData = %*{"description": decscription, "parameters": []}
                  
                  var matches: RegexMatch2
                  if route.description.find(
                    re"@openapi\s*\{((\s*\w+\s*[^\n]+|\s*@(params|responses)\s*\{[^\}]+?}\s*)+)\s*\}",
                    matches
                  ):
                    let text = route.description[matches.group(0)]
                    # Additional data
                    for m in text.findAll(re2"(?m)^\s*(\w[\w\d_]*)\s*=\s*([^\n]+)$"):
                      pathData[text[m.group(0)]] = %text[m.group(1)]
                    # Params
                    var paramMatches: RegexMatch2
                    if text.find(re2"@params\s*{((\s*\w[\w\d]*\!?\s*(:\s*\w+)?[^\n]+)+)\s*}", paramMatches):
                      let paramText = text[paramMatches.group(1)]
                      for m in paramText.findAll(
                        re2"(?m)^\s*(\w[\w\d_]*)(!)?\s*(:\s*\w[\w\d]*)?(\s*\-\s*[^\n]+)?"
                      ):
                        pathData["parameters"].add(%*{
                          "name": paramText[m.group(0)],
                          "required": m.group(1).len != 0,
                          "description":
                            if m.group(3).len != 0:
                              paramText[m.group(3)].replace(re"\s*\-\s*", "")
                            else:
                              "",
                          "in": "query",
                          "schema": {
                            "type":
                              if m.group(2).len != 0:
                                paramText[m.group(2)].replace(re":\s*", "")
                              else:
                                "string"
                          }
                        })
                  
                  for p in route.pathParams:
                    let param = %*{
                      "name": p.name,
                      "required": not p.optional,
                      "in": "path",
                      "schema": {
                        "type": p.paramType
                      }
                    }
                    pathData["parameters"].add(param)
                    
                  for m in route.httpMethod:
                    result["paths"][route.path][m.toLower()] = pathData
          ))
        else:
          newEmptyNode(),
        newCall("routes", s, body),
        newCall("start", s),
        newCall("addQuitProc", ident"finalizeProgram")
      ),
      nnkProcDef
    ),
    newCall("main")
  )
  result[0].addPragma(ident"gcsafe")


macro liveview*(body: untyped): untyped =
  for statement in body:
    if statement.kind in nnkCallKinds and statement[0].kind in {nnkStrLit, nnkTripleStrLit} and statement[1].kind == nnkStmtList:
      liveViews.add(newStmtList(statement[0], statement[1]))


when defined(napibuild):
  template handleApiDoc*(self: Server) =
    for route in self.routes:
      if not route.hasHttpMethod(@["MIDDLEWARE", "NOTFOUND"]):
        let routeData = handleRoute(route.path)
        if route.httpMethod == @["STATICFILE"]:
          apiDocData.add(newApiDocObject(
            @["GET"],
            "Fetch file from directory: " & route.purePath,
            routeData.path,
            routeData.pathParams,
            routeData.requestModels,
          ))
        else:
          apiDocData.add(newApiDocObject(
            route.httpMethod,
            route.docs,
            routeData.path,
            routeData.pathParams,
            routeData.requestModels,
          ))

  template handleNodeRequest*(self: Server, req: Request, urlPath: string) =
    var reqResponded = false
    for route in self.routes:
      if (
          (@["NOTFOUND"] == route.httpMethod and not(reqResponded)) or
          (
            @["MIDDLEWARE"] == route.httpMethod or
            (
              (contains(route.httpMethod, $get(req.httpMethod)) and route.pattern in urlPath) or
              (hasHttpMethod(route, @["STATICFILE", "WEBSOCKET"]) and route.pattern in urlPath)
            )
          )
        ):
        {.cast(gcsafe).}:
          if @["MIDDLEWARE"] != route.httpMethod:
            reqResponded = true
          if @["STATICFILE"] == route.httpMethod:
            var routeData = handleRoute(route.path)
            let
              founded_regexp_matches = findAll(urlPath, route.pattern)
              funcParams = getRouteParams(routeData, founded_regexp_matches, urlPath, force = true)
              fileName = $getStr(funcParams["file"])
              file =
                if not route.purePath.endsWith("/") and not fileName.startsWith("/"):
                  route.purePath & "/" & fileName
                else:
                  route.purePath & fileName
            if fileExists(file):
              await req.answerFile(file)
          elif @["WEBSOCKET"] == route.httpMethod:
            var
              wsClient = await req.newWebSocket()
              handler = getProperty(getGlobal(), route.handler)
              wsConnection = wsClient.newWebSocketObj("")
              wsId = registerWsClient(wsConnection)
            var httpRequest = toObject({
              "path": urlPath,
              "websocketId": wsId,
              "data": wsConnection.data,
              "state": $(wsConnection.state)
            })
            echo httpRequest
            try:
              wsConnection.state = wssConnect
              httpRequest["state"] = jsObj($wsConnection.state)
              discard callFunction(handler, [httpRequest], getGlobal())
              wsConnection.state = wssOpen
              httpRequest["state"] = jsObj($wsConnection.state)
              discard callFunction(handler, [httpRequest], getGlobal())
              while wsClient.readyState == Open:
                let wsData = await wsClient.receiveStrPacket()
                wsConnection.data = wsData
                httpRequest["state"] = jsObj($wsConnection.state)
                httpRequest["data"] = jsObj(wsConnection.data)
                discard callFunction(handler, [httpRequest], getGlobal())
            except WebSocketClosedError:
              wsConnection.state = wssClose
            except WebSocketHandshakeError:
              logging.error("Invalid WebSocket handshake. Headers haven't Sec-WebSocket-Version!")
              wsConnection.state = wssHandshakeError
            except WebSocketProtocolMismatchError:
              logging.error(fmt"Socket tried to use an unknown protocol: {getCurrentExceptionMsg()}")
              wsConnection.state = wssMismatchProtocol
            except WebSocketError:
              logging.error(fmt"Unexpected socket error: {getCurrentExceptionMsg()}")
              wsConnection.state = wssError
            except Exception:
              logging.error(fmt"Unexpected error: {getCurrentExceptionMsg()}")
              wsConnection.state = wssError
            httpRequest["data"] = jsObj("")
            httpRequest["state"] = jsObj($wsConnection.state)
            discard callFunction(handler, [httpRequest], getGlobal())
            unregisterWsClient(wsId)
            wsClient.close()
          else:
            let queryFromUrl = block:
              let val = split(req.path.get(), "?")
              if len(val) >= 2:
                val[1]
              else:
                ""
            let query = parseQuery(queryFromUrl)
            var routeData = handleRoute(route.path)
            var handler = getProperty(getGlobal(), route.handler)
            let founded_regexp_matches = findAll(urlPath, route.pattern)
            # Setup HttpRequest
            var httpRequest = toObject({
              "path": urlPath,
              "queries": query.toJsObj(),
              "headers": req.headers.get().toJsObj(),
              "cookies": inCookies.toJsObj(),
              "hostname": req.ip,
              "method": $req.httpMethod.get(),
              "reqId": req.registerRequest()
            })
            var params: RouteObject
            if req.body.isSome():
              httpRequest["body"] = jsObj(req.body.get())
              params = getRouteParams(routeData, founded_regexp_matches, urlPath, @[], req.body.get(), force = true)
            else:
              params = getRouteParams(routeData, founded_regexp_matches, urlPath, @[], force = true)
            httpRequest["params"] = params
            # Get function params
            var response = callFunction(handler, [httpRequest], getGlobal())
            if @["MIDDLEWARE"] != route.httpMethod:
              case response.kind
              of napi_undefined:
                discard
              of napi_null:
                req.answer("null")
              of napi_string:
                req.answer(response.getStr)
              of napi_number:
                req.answer($response.getInt)
              of napi_boolean:
                req.answer($response.getBool)
              of napi_object:
                # When object is response
                if response.hasOwnProperty("$data"):
                  let
                    resp = response["$data"]
                    httpCode = HttpCode(if response.hasOwnProperty("$code"): response["$code"].getInt else: 200)
                    headers =
                      if response.hasOwnProperty("$headers"):
                        let json = tryGetJson(response["$headers"])
                        json.toHttpHeaders
                      else:
                        newHttpHeaders([
                          ("Content-Type", "text/plain; charset=utf-8")
                        ])
                  case resp.kind
                  of napi_undefined:
                    req.answer("", httpCode, headers);
                  of napi_null:
                    req.answer("null", httpCode, headers)
                  of napi_string:
                    req.answer(resp.getStr, httpCode, headers)
                  of napi_number:
                    req.answer($resp.getInt, httpCode, headers)
                  of napi_boolean:
                    req.answer($resp.getBool, httpCode, headers)
                  of napi_object:
                    let stringRepr = $napiCall("JSON.stringify", [resp]).getStr
                    try:
                      let json = parseJson(stringRepr)
                      req.answerJson(json, httpCode, headers)
                    except JsonParsingError:
                      req.answer(stringRepr, httpCode, headers)
                  else:
                    discard
                else:
                  # Object is just JSON
                  let stringRepr = $napiCall("JSON.stringify", [response]).getStr
                  try:
                    let json = parseJson(stringRepr)
                    req.answerJson(json)
                  except JsonParsingError:
                    req.answer(stringRepr)
              else:
                discard
      if reqResponded:
        break      
