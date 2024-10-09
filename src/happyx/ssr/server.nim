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
## Just use `query?name` to get any query param. By default returns `""`
## 
## If you want to use [arrays in query](https://github.com/HapticX/happyx/issues/101) just use
## `queryArr?name` to get any array query param.
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
  std/asyncmacro,
  std/macrocache,
  std/strformat,
  std/asyncfile,
  std/segfaults,
  std/mimetypes,
  std/strutils,
  std/strtabs,
  std/logging,
  std/cookies,
  std/options,
  std/macros,
  std/tables,
  std/colors,
  std/json,
  std/os,
  checksums/md5,
  # HappyX
  ./[cors, types, utils, websockets],
  ../core/[exceptions, constants],
  ../private/[macro_utils],
  ../spa/tag,
  ../routing/[routing, mounting],
  ../sugar/sgr


when enableLiveViews:
  import
    ../spa/renderer,
    ./liveviews/[utils, liveviews]
  
  export
    liveviews


when enableDefaultDecorators:
  import ../routing/decorators


export
  strutils,
  strtabs,
  strformat,
  asyncdispatch,
  asyncfile,
  logging,
  cookies,
  colors,
  utils,
  json,
  os,
  types


when enableApiDoc:
  import
    nimja,
    ./docs/autodocs
  export autodocs


var
  pointerServer: ptr Server
  loggerCreated: bool = false


when defined(napibuild):
  import ./bindings/javascript
elif not defined(docgen) and not nim_2_0_0:
  import std/exitprocs

  proc ctrlCHook() {.noconv.} =
    quit(QuitSuccess)
  
  proc onQuit() {.noconv.} =
    when int(enableHttpBeast) + int(enableHttpx) + int(enableMicro) + int(enableBuiltin) == 0:
      try:
        pointerServer[].instance.close()
      except:
        discard
  
  setControlCHook(ctrlCHook)
  addExitProc(onQuit)


import ./handlers
export handlers


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
    when enableDefaultComponents:
      result = Server(
        address: address,
        port: port,
        components: newTable[string, BaseComponent](),
        logger:
          when enableColors:
            if loggerCreated:
              newConsoleLogger(lvlNone, fgColored("[$date at $time]:$levelname ", fgYellow))
            else:
              loggerCreated = true
              newConsoleLogger(lvlInfo, fgColored("[$date at $time]:$levelname ", fgYellow))
          else:
            if loggerCreated:
              newConsoleLogger(lvlNone, "[$date at $time]:$levelname ")
            else:
              loggerCreated = true
              newConsoleLogger(lvlInfo, "[$date at $time]:$levelname ")
      )
    else:
      result = Server(
        address: address,
        port: port,
        logger:
          when enableColors:
            if loggerCreated:
              newConsoleLogger(lvlNone, fgColored("[$date at $time]:$levelname ", fgYellow))
            else:
              loggerCreated = true
              newConsoleLogger(lvlInfo, fgColored("[$date at $time]:$levelname ", fgYellow))
          else:
            if loggerCreated:
              newConsoleLogger(lvlNone, "[$date at $time]:$levelname ")
            else:
              loggerCreated = true
              newConsoleLogger(lvlInfo, "[$date at $time]:$levelname ")
      )
  when enableHttpx or enableHttpBeast or enableBuiltin:
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
  try:
    when enableDebug or exportPython or defined(napibuild):
      info "Server started at http://" & `server`.address & ":" & $`server`.port
    when not declared(handleRequest):
      proc handleRequest(req: Request): Future[void] {.async.} =
        discard
    when not defined(hpxServeAsync):
      when enableHttpx or enableBuiltin:
        run(handleRequest, `server`.instance)
      elif enableHttpBeast:
        {.cast(gcsafe).}:
          run(handleRequest, `server`.instance)
      else:
        waitFor `server`.instance.serve(Port(`server`.port), handleRequest, `server`.address)
    else:
      when enableHttpx or enableBuiltin:
        asyncCheck runAsync(handleRequest, `server`.instance)
      elif enableHttpBeast:
        {.cast(gcsafe).}:
          run(handleRequest, `server`.instance)
      else:
        asyncCheck `server`.instance.serve(Port(`server`.port), handleRequest, `server`.address)
  except OSError:
    styledEcho fgYellow, "Try to use another port instead of ", $`server`.port
    echo getCurrentExceptionMsg()
  except:
    echo getCurrentExceptionMsg()


{.experimental: "dotOperators".}
macro `.`*(obj: JsonNode, field: untyped): JsonNode =
  newCall("[]", obj, newLit($field.toStrLit))


const defaultHeaders = "Content-Type: text/plain;charset=utf-8"


template answer*(
    req: Request,
    message: string | int | float | bool | char,
    code: HttpCode = Http200
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
  const useHeaders = declared(outHeaders) or declared(outCookies) or corsRegistered.value > 0
  when useHeaders:
    var h = newHttpHeaders([
      ("Content-Type", "text/plain;charset=utf-8")
    ])
  when corsRegistered.value > 0:
    when exportJvm or exportPython or defined(napibuild):
      when enableHttpBeast or enableHttpx or enableBuiltin:
        addCORSHeaders(req.ip, h)
      else:
        addCORSHeaders(req.hostname, h)
    else:
      h.addCORSHeaders()
  when declared(outHeaders):
    for key, val in outHeaders.pairs():
      h[key] = val
  # HTTPX
  when enableHttpx or enableBuiltin:
    when useHeaders:
      var headersArr = ""
      for key, value in h.pairs():
        headersArr &= key & ':' & value & "\r\n"
      when declared(outCookies):
        for cookie in outCookies:
          headersArr &= cookie & "\r\n"
      if headersArr.len > 0:
        headersArr.delete(headersArr.len-2..headersArr.len-1)
    
    # check safety requests
    when enableSafeRequests:
      when declared(statusCode):
        when statusCode is int:
          req.send(statusCode.HttpCode, $message, when useHeaders: headersArr else: defaultHeaders)
        else:
          req.send(code, $message, when useHeaders: headersArr else: defaultHeaders)
      else:
        req.send(code, $message, when useHeaders: headersArr else: defaultHeaders)
    else:
      # Use unsafeSend to improve speed
      var data: string = "HTTP/1.1 "
      when declared(statusCode):
        when statusCode is int:
          data &= $statusCode
        else:
          data &= $code
      else:
        data &= $code
      when message is string:
        data &= "\c\LContent-Length:" & $len(message)
        data &= "\c\L" & (when useHeaders: headersArr else: defaultHeaders) & "\c\L\c\L" & message
      else:
        data &= "\c\LContent-Length:" & $len($message)
        data &= "\c\L" & (when useHeaders: headersArr else: defaultHeaders) & "\c\L\c\L" & $message
      req.unsafeSend(data)
  # HTTP BEAST
  elif enableHttpBeast:
    when useHeaders:
      var headersArr = ""
      for key, value in h.pairs():
        headersArr &= key & ':' & value & "\r\n"
      when declared(outCookies):
        for cookie in outCookies:
          headersArr &= cookie & "\r\n"
      if headersArr.len > 0:
        headersArr.delete(headersArr.len-2..headersArr.len-1)
    when declared(statusCode):
      when statusCode is int:
        req.send(statusCode.HttpCode, $message, when useHeaders: headersArr else: defaultHeaders)
      else:
        req.send(code, $message, when useHeaders: headersArr else: defaultHeaders)
    else:
      req.send(code, $message, when useHeaders: headersArr else: defaultHeaders)
  # ASYNC HTTP SERVER / MICRO ASYNC HTTP SERVER
  else:
    when useHeaders:
      when declared(outCookies):
        for cookie in outCookies:
          let data = cookie.split(":", 1)
          h.add("Set-Cookie", data[1].strip())
    else:
      let h = newHttpHeaders([("Content-Type", "text/plain;charset=utf-8")])
    when declared(statusCode):
      when statusCode is int:
        await req.respond(statusCode.HttpCode, $message, h)
      else:
        await req.respond(code, $message, h)
    else:
      await req.respond(code, $message, h)


template answer*(
    req: Request,
    message: string | int | float | bool | char,
    code: HttpCode = Http200,
    headers: HttpHeaders,
    contentLength: Option[int] = int.none
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
  when corsRegistered.value > 0:
    when exportJvm or exportPython or defined(napibuild):
      when enableHttpBeast or enableHttpx or enableBuiltin:
        addCORSHeaders(req.ip, h)
      else:
        addCORSHeaders(req.hostname, h)
    else:
      h.addCORSHeaders()
  when declared(outHeaders):
    for key, val in outHeaders.pairs():
      h[key] = val
  # HTTPX
  when enableHttpx or enableBuiltin:
    var headersArr = ""
    for key, value in h.pairs():
      headersArr &= key & ':' & value & "\c\L"
    when declared(outCookies):
      for cookie in outCookies:
        headersArr &= cookie & "\c\L"
    if headersArr.len > 0:
      headersArr.delete(headersArr.len-2..headersArr.len-1)
    if contentLength.isSome:
      # useful for file answers
      when enableSafeRequests:
        when declared(statusCode):
          when statusCode is int:
            req.send(statusCode.HttpCode, $message, contentLength, headersArr)
          else:
            req.send(code, $message, contentLength, headersArr)
        else:
          req.send(code, $message, contentLength, headersArr)
      else:
        # Use unsafeSend to improve speed
        var data: string = "HTTP/1.1 "
        when declared(statusCode):
          when statusCode is int:
            data &= $statusCode
          else:
            data &= $code
        else:
          data &= $code
        when message is string:
          data &= "\c\LContent-Length:" & $contentLength.get()
          data &= "\c\L" & headersArr & "\c\L\c\L" & message
        else:
          data &= "\c\LContent-Length:" & $contentLength.get()
          data &= "\c\L" & headersArr & "\c\L\c\L" & $message
        req.unsafeSend(data)
    else:
      when enableSafeRequests:
        when declared(statusCode):
          when statusCode is int:
            req.send(statusCode.HttpCode, $message, headersArr)
          else:
            req.send(code, $message, headersArr)
        else:
          req.send(code, $message, headersArr)
      else:
        # Use unsafeSend to improve speed
        var data: string = "HTTP/1.1 "
        when declared(statusCode):
          when statusCode is int:
            data &= $statusCode
          else:
            data &= $code
        else:
          data &= $code
        when message is string:
          data &= "\c\LContent-Length:" & $len(message)
          data &= "\c\L" & headersArr & "\c\L\c\L" & message
        else:
          data &= "\c\LContent-Length:" & $len($message)
          data &= "\c\L" & headersArr & "\c\L\c\L" & $message
        req.unsafeSend(data)
  # HTTP BEAST
  elif enableHttpBeast:
    var headersArr = ""
    for key, value in h.pairs():
      headersArr &= key & ':' & value & "\r\n"
    when declared(outCookies):
      for cookie in outCookies:
        headersArr &= cookie & "\r\n"
    if headersArr.len > 0:
      headersArr.delete(headersArr.len-2..headersArr.len-1)
    when declared(statusCode):
      when statusCode is int:
        req.send(statusCode.HttpCode, $message, headersArr)
      else:
        req.send(code, $message, headersArr)
    else:
      req.send(code, $message, headersArr)
  # ASYNC HTTP SERVER / MICRO ASYNC HTTP SERVER
  else:
    when declared(outCookies):
      for cookie in outCookies:
        let data = cookie.split(":", 1)
        h.add("Set-Cookie", data[1].strip())
    when declared(statusCode):
      when statusCode is int:
        await req.respond(statusCode.HttpCode, $message, h)
      else:
        await req.respond(code, $message, h)
    else:
      await req.respond(code, $message, h)


when enableHttpBeast:
  proc send*(ws: AsyncWebSocket, data: string) {.async.} =
    await ws.sendText(data)


template answerJson*(req: Request, data: untyped, code: HttpCode = Http200,
                     headers: HttpHeaders = newHttpHeaders([("Content-Type", "application/json;charset=utf-8")])): untyped =
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
                     headers: HttpHeaders = newHttpHeaders([("Content-Type", "text/html;charset=utf-8")])): untyped =
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
    answer(req, data, code, headers)
  else:
    answer(req, $data, code, headers)


when enableHttpx or enableHttpBeast or enableBuiltin:
  proc send*(request: Request, content: string): Future[void] {.inline.} =
    ## Sends `content` to the client.
    request.unsafeSend(content)
    result = newFuture[void]()
    complete(result)


proc answerFile*(req: Request, filename: string,
                 code: HttpCode = Http200, asAttachment = false,
                 bufSize: int = 40960, forceResponse: bool = false,
                 headers: CustomHeaders = newCustomHeaders()) {.async.} =
  ## Respond file to request.
  ## 
  ## Automatically enables streaming response when file size is too big (> 1 000 000 bytes)
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
    info = getFileInfo(filename)
    fileSize = info.size.int
    lastModified = info.lastWriteTime
    etag = getMD5(fmt"{filename}-{lastModified}-{fileSize}")
  var
    f = openAsync(filename, fmRead)
    h = @[
      ("Content-Type", fmt"{contentType};charset=utf-8"),
      ("Last-Modified", $lastModified),
      ("Etag", etag),
    ]
  
  if asAttachment:
    h.add(("Content-Disposition", "attachment"))

  for header, value in headers.pairs:
    h.add((header, value))
  
  if fileSize > 1_000_000 and not forceResponse:
    req.answer("", Http200, newHttpHeaders(h), contentLength = some(fileSize))
    while true:
      let val = await f.read(bufSize)
      if val.len > 0:
        when enableHttpx or enableHttpBeast or enableBuiltin:
          await req.send(val)
        else:
          await req.client.send(val)
      else:
        break
    f.close()
  else:
    let content = await f.readAll()
    f.close()
    req.answer(content, headers = newHttpHeaders(h))


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
        node[i] = newNimNode(nnkWhenStmt).add(newNimNode(nnkElifBranch).add(
          newCall("declared", ident"outHeaders"),
          newCall("await", newCall("answerFile", ident"req", child[0][1], newNimNode(nnkExprEqExpr).add(ident"headers", ident"outHeaders")))
        ), newNimNode(nnkElse).add(
          newCall("await", newCall("answerFile", ident"req", child[0][1]))
        ))
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
            when enableAutoTranslate:
              newCall("answer", ident"req", newCall("translate", child[0]))
            else:
              newCall("answer", ident"req", child[0])
          )
        )
      # Really complete route after any return statement
      node.insert(i+1, newNimNode(nnkBreakStmt).add(ident"__handleRequestBlock"))
    else:
      node[i].detectReturnStmt(true)
  # Replace last node
  if replaceReturn or node.kind in AtomicNodes:
    return
  if node[^1].kind in [nnkCall, nnkCommand]:
    if node[^1][0].kind == nnkIdent and $node[^1][0] in ["answer", "echo", "translate"]:
      return
    elif node[^1][0].kind == nnkDotExpr and ($node[^1][0][1]).toLower().startsWith("answer"):
      return
  if not node[^1].isExpr:
    return
  if node[^1].kind == nnkCall and $node[^1][0] == "buildHtml":
    node[^1] = newCall("answerHtml", ident"req", node[^1].copy())
    node.add(newNimNode(nnkBreakStmt).add(ident"__handleRequestBlock"))
    return
  elif node[^1].kind == nnkTableConstr:
    node[^1] = newCall("answerJson", ident"req", node[^1].copy())
  elif node[^1].kind in [nnkStrLit, nnkTripleStrLit]:
    when enableAutoTranslate:
      node[^1] = newCall("answer", ident"req", formatNode(newCall("translate", node[^1].copy())))
    else:
      node[^1] = newCall("answer", ident"req", formatNode(node[^1].copy()))
  else:
    when enableAutoTranslate:
      node[^1] = newCall("answer", ident"req", newCall("translate", node[^1].copy()))
    else:
      node[^1] = newCall("answer", ident"req", node[^1].copy())
  node[^1] = newNimNode(nnkWhenStmt).add(newNimNode(nnkElifBranch).add(
    newCall("is", newCall("type", node[^1][^1].copy()), ident"void"),
    node[^1][^1].copy()
  ), newNimNode(nnkElse).add(
    newStmtList(
      node[^1].copy(),
      # Really complete route after any return statement
      newNimNode(nnkBreakStmt).add(ident"__handleRequestBlock")
    )
  ))


macro routes*(server: Server, body: untyped = newStmtList()): untyped =
  ## You can create routes with this marco
  ## 
  ## #### Available Path Params
  ## - `bool`: any boolean (`y`, `yes`, `on`, `1` and `true` for true; `n`, `no`, `off`, `0` and `false` for false).
  ## - `int`: any integer.
  ## - `float`: any float number.
  ## - `word`: any word.
  ## - `string`: any string excludes `"/"`.
  ## - `enum(EnumName)`: any string excludes `"/"`. Converts into `EnumName`.
  ## - `path`: any float number includes `"/"`.
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
    wsNewConnection = newStmtList()
    wsClosedConnection = newStmtList()
    wsMismatchProtocol = newStmtList()
    variables = newStmtList()
    wsError = newStmtList()
  var
    # Handle requests
    body = body
    stmtList = newStmtList()
    staticDirs: seq[NimNode]
    notFoundNode = newEmptyNode()
    procStmt = newProc(
      ident"handleRequest",
      [
        newNimNode(nnkBracketExpr).add(ident"Future", ident"void"),
        newIdentDefs(ident"req", ident"Request")
      ],
      when enableSafeRequests:
        newNimNode(nnkTryStmt).add(
          newNimNode(nnkBlockStmt).add(
            ident"__handleRequestBlock",
            stmtList,
          ),
          newNimNode(nnkExceptBranch).add(
            newCall(
              ident"answer", ident"req",
              newCall("fmt", newLit"Internal Server Error: {getCurrentExceptionMsg()}"),
              ident"Http500"
            )
          )
        )
      else:
        newNimNode(nnkBlockStmt).add(
          ident"__handleRequestBlock",
          stmtList,
        ),
    )
    caseRequestMethodsStmt = newNimNode(nnkCaseStmt)
    # caseRequestMethodsStmt = newNimNode(nnkIfStmt)
    methodTable = newTable[string, NimNode]()
    finalize = newStmtList()
    setup = newStmtList()
  
  when enableLiveViews:
    body.handleLiveViews()

  when enableHttpx or enableHttpBeast or enableBuiltin:
    var path = newCall("decodeUrl", newNimNode(nnkBracketExpr).add(
      newCall("split", newCall("get", newCall("path", ident"req")), newLit('?')),
      newLit(0)
    ))
    let
      reqMethod = newCall("get", newDotExpr(ident"req", ident"httpMethod"))
      hostname = newDotExpr(ident"req", ident"ip")
      headers = newCall("get", newDotExpr(ident"req", ident"headers"))
      acceptLanguage = newNimNode(nnkBracketExpr).add(
        newCall(
          "split", newNimNode(nnkBracketExpr).add(headers, newLit"accept-language"), newLit(',')
        ), newLit(0)
      )
      val = ident(fmt"_val")
      url = newStmtList(
        newLetStmt(val, newCall("split", newCall("get", newCall("path", ident"req")), newLit"?")),
        newNimNode(nnkIfStmt).add(
          newNimNode(nnkElifBranch).add(
            newCall(">=", newCall("len", val), newLit(2)),
            newNimNode(nnkBracketExpr).add(val, newLit(1))
          ), newNimNode(nnkElse).add(
            newLit("")
          )
        )
      )
  else:
    var path = newCall("decodeUrl", newDotExpr(newDotExpr(ident"req", ident"url"), ident"path"))
    let
      reqMethod = newDotExpr(ident"req", ident"reqMethod")
      hostname = newDotExpr(ident"req", ident"hostname")
      headers = newDotExpr(ident"req", ident"headers")
      acceptLanguage = newNimNode(nnkBracketExpr).add(
        newCall(
          "split", newNimNode(nnkBracketExpr).add(headers, newLit"accept-language"), newLit(',')
        ), newLit(0)
      )
      url = newDotExpr(newDotExpr(ident"req", ident"url"), ident"query")
  let
    directoryFromPath = newCall(
      "&",
      newLit".",
      newCall("replace", pathIdent, newLit('/'), ident"DirSep")
    )
    cookiesOutVar = newCall(newNimNode(nnkBracketExpr).add(ident"newSeq", ident"string"))
    cookiesInVar = newNimNode(nnkIfStmt).add(
      newNimNode(nnkElifBranch).add(
        newCall("hasKey", headers, newLit"cookie"),
        newCall("parseCookies", newCall("$", newNimNode(nnkBracketExpr).add(headers, newLit"cookie")))
      ), newNimNode(nnkElse).add(
        newCall("parseCookies", newLit(""))
      )
    )
    isWebsocketConnection =
      newCall(
        "and",
        newCall(
          "and",
          newCall("hasKey", headers, newLit"connection"),
          newCall("hasKey", headers, newLit"upgrade"),
        ),
        newCall(
          "and",
          newCall("contains", newCall("[]", headers, newLit"connection"), newLit"upgrade"),
          newCall("==", newCall("toLower", newCall("[]", headers, newLit"upgrade", newLit(0))), newLit"websocket"),
        )
      )
    wsClientI = ident"wsClient"
  
  when enableDebug:
    caseRequestMethodsStmt.add(ident"reqMethod")
  else:
    caseRequestMethodsStmt.add(reqMethod)
  
  procStmt.addPragma(ident"async")
  procStmt.addPragma(ident"gcsafe")

  # Find mounts
  body.findAndReplaceMount()

  for key, val in sugarRoutes.pairs():
    if ($val[0]).toLower() == "any":
      body.add(newCall(newLit(key), val[1]))
    elif ($val[0]).toLower() in httpMethods:
      body.add(newNimNode(nnkCommand).add(
        val[0],
        newLit(key),
        val[1]
      ))
  
  var
    nextRouteDecorators: seq[tuple[name: string, args: seq[NimNode]]] = @[]

  for statement in body:
    if statement.kind == nnkDiscardStmt:
      continue
    if statement.kind in [nnkCall, nnkCommand, nnkPrefix]:
      if statement[^1].kind == nnkStmtList:
        # Check variable usage
        if statement[^1].isIdentUsed(ident"statusCode"):
          statement[^1].insert(0, newVarStmt(ident"statusCode", newLit(200)))
        if statement[^1].isIdentUsed(ident"outHeaders"):
          statement[^1].insert(0, newVarStmt(ident"outHeaders", newCall("newCustomHeaders")))
        if statement[^1].isIdentUsed(ident"outCookies") or statement[^1].isIdentUsed(ident"startSession") or statement[^1].isIdentUsed(ident"getSession"):
          statement[^1].insert(0, newVarStmt(ident"outCookies", cookiesOutVar))
      # Decorators
      if statement.kind == nnkPrefix and $statement[0] == "@" and statement[1].kind == nnkIdent:
        # @Decorator
        nextRouteDecorators.add(($statement[1], @[]))
      # @Decorator()
      elif statement.kind == nnkCall and statement[0].kind == nnkPrefix and $statement[0][0] == "@" and statement.len == 1:
        nextRouteDecorators.add(($statement[0][1], @[]))
      # @Decorator(arg1, arg2, ...)
      elif statement.kind == nnkCall and statement[0].kind == nnkPrefix and $statement[0][0] == "@" and statement.len > 1:
        nextRouteDecorators.add(($statement[0][1], statement[1..^1]))
      # "/...": statement list
      elif statement[1].kind == nnkStmtList and statement[0].kind == nnkStrLit:
        detectReturnStmt(statement[1])
        when enableDefaultDecorators:
          for route in nextRouteDecorators:
            decorators[route.name](@["GET"], $statement[0], statement[1], route.args)
        let exported = exportRouteArgs(pathIdent, statement[0], statement[1])
        if exported.len > 0:  # /my/path/with{custom:int}/{param:path}
          methodTable.mgetOrPut("GET", newNimNode(nnkIfStmt)).add(exported)
        else:  # /just-my-path
          methodTable.mgetOrPut("GET", newNimNode(nnkIfStmt)).add(newNimNode(nnkElifBranch).add(
            newCall("==", pathIdent, statement[0]), statement[1]
          ))
        nextRouteDecorators = @[]
      # [get, post, ...] "/...": statement list
      elif statement.len == 3 and statement[2].kind == nnkStmtList and statement[0].kind == nnkBracket and statement[1].kind == nnkStrLit and statement[0].len > 0:
        detectReturnStmt(statement[2])
        var httpMethods: seq[string] = @[]
        for i in statement[0]:
          httpMethods.add($i)
        when enableDefaultDecorators:
          for route in nextRouteDecorators:
            decorators[route.name](httpMethods, $statement[0], statement[1], route.args)
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
          for i in httpMethods:
            methodTable.mgetOrPut(i.toUpper, newNimNode(nnkIfStmt)).add(exported)
        else:  # /just-my-path
          for i in httpMethods:
            methodTable.mgetOrPut(i.toUpper, newNimNode(nnkIfStmt)).add(newNimNode(nnkElifBranch).add(
              newCall(
                "and",
                newCall("contains", methods, newCall("toLower", newCall("$", reqMethod))),
                newCall("==", pathIdent, statement[1])
              ), statement[2]
            ))
        nextRouteDecorators = @[]
      # mount ...
      elif statement.kind == nnkCommand and statement[0] == ident"mount" and statement[1].kind == nnkInfix and statement[1][0] == ident"->":
        nextRouteDecorators = @[]
      # reqMethod "/...":
      #   ...
      elif statement[0].kind == nnkIdent and statement[0] != ident"mount" and statement[1].kind in {nnkStrLit, nnkTripleStrLit, nnkInfix}:
        let
          name = ($statement[0]).toUpper()
          slash = newLit"/"
        when enableDefaultDecorators:
          for route in nextRouteDecorators:
            decorators[route.name](@[$statement[0]], $statement[1], statement[2], route.args)
        if name == "STATICDIR":
          # Just path
          var
            staticPath = newLit""
            directory = newLit""
            extensions: seq[string] = @[]
          
          # staticDir "/directory"
          if statement[1].kind in [nnkStrLit, nnkTripleStrLit, nnkIdent, nnkDotExpr]:
            staticPath = statement[1]
            directory = statement[1]
            staticDirs.add(
              newNimNode(nnkElifBranch).add(
                newCall(
                  "and",
                  newCall(
                    "or",
                    newCall("startsWith", pathIdent, statement[1]),
                    newCall("startsWith", pathIdent, newCall("&", slash, statement[1])),
                  ), newCall(
                    "fileExists",
                    directoryFromPath
                  )
                ),
                newStmtList(
                  newNimNode(nnkWhenStmt).add(newNimNode(nnkElifBranch).add(
                    newCall("declared", ident"outHeaders"),
                    newCall("await", newCall("answerFile", ident"req", directoryFromPath, newNimNode(nnkExprEqExpr).add(ident"headers", ident"outHeaders")))
                  ), newNimNode(nnkElse).add(
                    newCall("await", newCall("answerFile", ident"req", directoryFromPath))
                  ))
                )
              )
            )
          # staticDir "/path" -> "directory" ~ "js,html"
          elif statement[1].kind == nnkInfix and statement[1][0] == ident"->" and statement[1][2].kind == nnkInfix and statement[1][2][0] == ident"~":
            staticPath = statement[1][1]
            directory = statement[1][2][1]
            extensions = ($statement[1][2][2]).split(",")
          # staticDir "/directory" ~ "js,html"
          elif statement[1].kind == nnkInfix and statement[1][0] == ident"~":
            staticPath = statement[1][1]
            directory = statement[1][1]
            extensions = ($statement[1][2]).split(",")
          # staticDir "/directory" -> "js,html"
          elif statement[1].kind == nnkInfix and statement[1][0] == ident"->":
            staticPath = statement[1][1]
            directory = statement[1][2]

          if directory == staticPath:
            let answerStatic =
              if extensions.len > 0:
                newNimNode(nnkIfStmt).add(newNimNode(nnkElifBranch).add(
                  newCall(
                    "contains",
                    bracket(extensions),
                    newCall("[]", newCall("split", directoryFromPath, newLit"."), newCall("^", newLit(1)))
                  ), newStmtList(
                    newNimNode(nnkWhenStmt).add(newNimNode(nnkElifBranch).add(
                      newCall("declared", ident"outHeaders"),
                      newCall("await", newCall("answerFile", ident"req", directoryFromPath, newNimNode(nnkExprEqExpr).add(ident"headers", ident"outHeaders")))
                    ), newNimNode(nnkElse).add(
                      newCall("await", newCall("answerFile", ident"req", directoryFromPath))
                    ))
                  )
                ), newNimNode(nnkElse).add(
                  newCall(ident"answer", ident"req", newLit"Not found", ident"Http404")
                ))
              else:
                newNimNode(nnkWhenStmt).add(newNimNode(nnkElifBranch).add(
                  newCall("declared", ident"outHeaders"),
                  newCall("await", newCall("answerFile", ident"req", directoryFromPath, newNimNode(nnkExprEqExpr).add(ident"headers", ident"outHeaders")))
                ), newNimNode(nnkElse).add(
                  newCall("await", newCall("answerFile", ident"req", directoryFromPath))
                ))
            staticDirs.add(
              newNimNode(nnkElifBranch).add(
                newCall(
                  "and",
                  newCall(
                    "or",
                    newCall("startsWith", pathIdent, staticPath),
                    newCall("startsWith", pathIdent, newCall("&", slash, statement[1])),
                  ), newCall(
                    "fileExists",
                    directoryFromPath
                  )
                ),
                answerStatic
              )
            )
          else:
            let
              route = if staticPath == slash: newLit"" else: staticPath
              path = if staticPath == slash: newCall("&", directory, slash) else: directory
            let dirFromPath = newCall(
              "&",
              newCall("&", newLit".", slash),
              newCall(
                "replace",
                newCall("replace", pathIdent, staticPath, path),
                newLit('/'), ident"DirSep"
              )
            )
            let answerStatic =
              if extensions.len > 0:
                newNimNode(nnkIfStmt).add(newNimNode(nnkElifBranch).add(
                  newCall(
                    "contains",
                    bracket(extensions),
                    newCall("[]", newCall("split", dirFromPath, newLit"."), newCall("^", newLit(1)))
                  ), newStmtList(
                    newNimNode(nnkWhenStmt).add(newNimNode(nnkElifBranch).add(
                      newCall("declared", ident"outHeaders"),
                      newCall("await", newCall("answerFile", ident"req", dirFromPath, newNimNode(nnkExprEqExpr).add(ident"headers", ident"outHeaders")))
                    ), newNimNode(nnkElse).add(
                      newCall("await", newCall("answerFile", ident"req", dirFromPath))
                    ))
                  )
                ), newNimNode(nnkElse).add(
                  newCall(ident"answer", ident"req", newLit"Not found", ident"Http404")
                ))
              else:
                newNimNode(nnkWhenStmt).add(newNimNode(nnkElifBranch).add(
                  newCall("declared", ident"outHeaders"),
                  newCall("await", newCall("answerFile", ident"req", dirFromPath, newNimNode(nnkExprEqExpr).add(ident"headers", ident"outHeaders")))
                ), newNimNode(nnkElse).add(
                  newCall("await", newCall("answerFile", ident"req", dirFromPath))
                ))
            staticDirs.add(
              newNimNode(nnkElifBranch).add(
                newCall(
                  "and",
                  newCall("startsWith", pathIdent, route),
                  newCall("fileExists", dirFromPath)
                ),
                answerStatic
              )
            )
          continue
          
          if statement[1].kind in {nnkStrLit, nnkTripleStrLit, nnkIdent, nnkDotExpr}:
            methodTable.mgetOrPut("GET", newNimNode(nnkIfStmt)).insert(
              0, newNimNode(nnkElifBranch).add(
                newCall(
                  "and",
                  newCall(
                    "or",
                    newCall("startsWith", pathIdent, statement[1]),
                    newCall("startsWith", pathIdent, newCall("&", slash, statement[1])),
                  ), newCall(
                    "fileExists",
                    directoryFromPath
                  )
                ),
                newStmtList(
                  newNimNode(nnkWhenStmt).add(newNimNode(nnkElifBranch).add(
                    newCall("declared", ident"outHeaders"),
                    newCall("await", newCall("answerFile", ident"req", directoryFromPath, newNimNode(nnkExprEqExpr).add(ident"headers", ident"outHeaders")))
                  ), newNimNode(nnkElse).add(
                    newCall("await", newCall("answerFile", ident"req", directoryFromPath))
                  ))
                )
              )
            )
          elif statement[1].kind == nnkInfix and statement[1][^1].kind == nnkInfix and statement[1][0] == ident"->" and statement[1][^1][0] == ident"~":
            # Path -> directory ~ extensions
            let
              route = if statement[1][1] == slash: newLit"" else: statement[1][1]
              path = if statement[1][1] == slash: newCall("&", statement[1][2], slash) else: statement[1][2]
            let dirFromPath = newCall(
              "&",
              newCall("&", newLit".", slash),
              newCall(
                "replace",
                newCall("replace", pathIdent, statement[1][1], path),
                newLit('/'), ident"DirSep"
              )
            )
            methodTable.mgetOrPut("GET", newNimNode(nnkIfStmt)).insert(
              0, newNimNode(nnkElifBranch).add(
                newCall(
                  "and",
                  newCall("startsWith", pathIdent, route),
                  newCall("fileExists", dirFromPath)
                ),
                newStmtList(
                  newNimNode(nnkWhenStmt).add(newNimNode(nnkElifBranch).add(
                    newCall("declared", ident"outHeaders"),
                    newCall("await", newCall("answerFile", ident"req", dirFromPath, newNimNode(nnkExprEqExpr).add(ident"headers", ident"outHeaders")))
                  ), newNimNode(nnkElse).add(
                    newCall("await", newCall("answerFile", ident"req", dirFromPath))
                  ))
                )
              )
            )
          else:
            # Path -> directory
            let
              route = if statement[1][1] == slash: newLit"" else: statement[1][1]
              path = if statement[1][1] == slash: newCall("&", statement[1][2], slash) else: statement[1][2]
            let dirFromPath = newCall(
              "&",
              newCall("&", newLit".", slash),
              newCall(
                "replace",
                newCall("replace", pathIdent, statement[1][1], path),
                newLit('/'), ident"DirSep"
              )
            )
            methodTable.mgetOrPut("GET", newNimNode(nnkIfStmt)).insert(
              0, newNimNode(nnkElifBranch).add(
                newCall(
                  "and",
                  newCall("startsWith", pathIdent, route),
                  newCall("fileExists", dirFromPath)
                ),
                newStmtList(
                  newNimNode(nnkWhenStmt).add(newNimNode(nnkElifBranch).add(
                    newCall("declared", ident"outHeaders"),
                    newCall("await", newCall("answerFile", ident"req", dirFromPath, newNimNode(nnkExprEqExpr).add(ident"headers", ident"outHeaders")))
                  ), newNimNode(nnkElse).add(
                    newCall("await", newCall("answerFile", ident"req", dirFromPath))
                  ))
                )
              )
            )
          continue
        let exported = exportRouteArgs(pathIdent, statement[1], statement[2])
        # Handle websockets
        if name == "WS":
          var (wsStmtList, insertWsList) = handleWebsockets(wsClosedConnection)
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
        nextRouteDecorators = @[]
      # notfound: statement list
      elif statement[1].kind == nnkStmtList and statement[0].kind == nnkIdent:
        case ($statement[0]).toLower()
        of "wsconnect":
          for i in statement[1]:
            wsNewConnection.add(i)
        of "wsclosed":
          for i in statement[1]:
            wsClosedConnection.add(i)
        of "wsmismatchprotocol":
          for i in statement[1]:
            wsMismatchProtocol.add(i)
        of "wserror":
          for i in statement[1]:
            wsError.add(i)
        of "finalize":
          finalize = statement[1]
        of "setup":
          setup = statement[1]
        of "notfound":
          detectReturnStmt(statement[1])
          notFoundNode = statement[1]
        of "onexception":
          detectReturnStmt(statement[1])
          statement[1].insert(0, newLetStmt(ident"e", newCall"getCurrentException"))
          onException["e"].add(statement[1])
          echo onException["e"].toStrLit
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
    immutableVars =
      when enableBuiltin:
        newNimNode(nnkLetSection).add(
          newNimNode(nnkVarTuple).add(
            ident"urlPath", ident"queryRaw", newEmptyNode(), newCall("get", newCall("pathWithQueries", ident"req"))
          )
        )
      else:
        newNimNode(nnkLetSection).add(
          newIdentDefs(ident"urlPath", newEmptyNode(), path),
        )
    mutableVars = newNimNode(nnkVarSection)

  # immutable variables
  stmtList.insert(0, immutableVars)
  stmtList.insert(0, mutableVars)
  
  when enableDebug:
    stmtList.add(newCall(
      "info",
      newCall("fmt", newLit"{reqMethod}::{urlPath}")
    ))

  # NodeJS Library
  when defined(napibuild):
    stmtList.add(newCall(
      "handleNodeRequest", ident"self", ident"req", ident"urlPath"
    ))
  # Python Library
  elif exportPython:
    stmtList.add(
      newVarStmt(ident"reqResponded", newLit(false))
    )
    stmtList.add(
      newCall(
        "handlePythonRequest", ident"self", ident"req", ident"urlPath"
      )
    )
  # JVM JNI Library
  elif exportJvm:
    stmtList.add(newCall(
      "handleJvmRequest", ident"self", ident"req", ident"urlPath"
    ))

  when not (exportPython or exportJvm or defined(napibuild)):
    var returnStmt = newStmtList(newNimNode(nnkReturnStmt).add(newLit""))
    detectReturnStmt(returnStmt)
    methodTable.mgetOrPut(
      "OPTIONS", newNimNode(nnkIfStmt)
    ).add(exportRouteArgs(pathIdent, newLit"/{p:path}", returnStmt))

  for key in methodTable.keys():
    caseRequestMethodsStmt.add(newNimNode(nnkOfBranch).add(
      newLit(parseEnum[HttpMethod](key)),
      methodTable[key]
    ))
    # caseRequestMethodsStmt.add(newNimNode(nnkElifBranch).add(
    #   newCall("==", reqMethod, newLit(parseEnum[HttpMethod](key))),
    #   methodTable[key]
    # ))
  
  for ifBranch in staticDirs:
    methodTable.mgetOrPut("GET", newNimNode(nnkIfStmt)).add(ifBranch)

  if notFoundNode.kind == nnkEmpty:
    # return 404 by default
    let elseStmtList = newStmtList()
    when enableDebug:
      elseStmtList.add(
        newCall(
          "warn",
          when enableColors:
            newCall(
              "fgColored", 
              newCall("fmt", newLit"{urlPath} is not found."), ident"fgYellow"
            )
          else:
            newCall("fmt", newLit"{urlPath} is not found.")
        )
      )
    elseStmtList.add(
      newCall(ident"answer", ident"req", newLit"Not found", ident"Http404")
    )
    notFoundNode = elseStmtList

  for ifStmt in methodTable.mvalues:
    # notfound if no route matched
    ifStmt.add(newNimNode(nnkElse).add(notFoundNode))

  caseRequestMethodsStmt.add(newNimNode(nnkElse).add(notFoundNode))
  when exportJvm or exportPython or defined(napibuild):
    stmtList.add(newNimNode(nnkIfStmt).add(newNimNode(nnkElifBranch).add(
      newCall("not", ident"reqResponded"),
      caseRequestMethodsStmt.copy()
    )))
  else:
    stmtList.add(caseRequestMethodsStmt)

  # Websocket type for different compile cases
  let wsType =
    when enableHttpBeast:
      ident"AsyncWebSocket"
    elif exportPython or exportJvm:
      newDotExpr(ident"ws", ident"WebSocket")
    else:
      ident"WebSocket"

  result = newStmtList(
    if stmtList.isIdentUsed(ident"wsConnections"):
      newNimNode(nnkVarSection).add(newIdentDefs(
        ident"wsConnections",
        newNimNode(nnkBracketExpr).add(ident"seq", wsType),
        newCall("@", newNimNode(nnkBracket)),
      ))
    else:
      newEmptyNode(),
    setup,
    if stmtList.isIdentUsed(ident"__wsError"):
      newProc(
        ident"__wsError",
        [newEmptyNode(), newIdentDefs(wsClientI, wsType)],
        wsError,
        nnkTemplateDef
      )
    else:
      newEmptyNode(),
    if stmtList.isIdentUsed(ident"__wsClosed"):
      newProc(
        ident"__wsClosed",
        [newEmptyNode(), newIdentDefs(wsClientI, wsType)],
        wsClosedConnection,
        nnkTemplateDef
      )
    else:
      newEmptyNode(),
    if stmtList.isIdentUsed(ident"__wsConnect"):
      newProc(
        ident"__wsConnect",
        [newEmptyNode(), newIdentDefs(wsClientI, wsType)],
        wsNewConnection,
        nnkTemplateDef
      )
    else:
      newEmptyNode(),
    if stmtList.isIdentUsed(ident"__wsMismatchProtocol"):
      newProc(
        ident"__wsMismatchProtocol",
        [newEmptyNode(), newIdentDefs(wsClientI, wsType)],
        wsMismatchProtocol,
        nnkTemplateDef
      )
    else:
      newEmptyNode(),
    procStmt,
    if finalize.len > 0:
      newProc(
        ident"finalizeProgram",
        [newEmptyNode()],
        finalize,
        pragmas = newNimNode(nnkPragma).add(ident"noconv")
      )
    else:
      newEmptyNode()
  )

  for v in countdown(variables.len-1, 0, 1):
    result.insert(0, variables[v])
  
  if stmtList.isIdentUsed(ident"query"):
    immutableVars.add(newIdentDefs(ident"queryFromUrl", newEmptyNode(), url))
    immutableVars.add(newIdentDefs(ident"query", newEmptyNode(), newCall("parseQuery", ident"queryFromUrl")))
  if stmtList.isIdentUsed(ident"queryArr"):
    when not exportPython and not defined(napibuild) and not exportJvm:
      immutableVars.add(newIdentDefs(ident"queryArr", newEmptyNode(), newCall("parseQueryArrays", ident"queryFromUrl")))
  if stmtList.isIdentUsed(ident"translate") or stmtList.isIdentUsed(ident"acceptLanguage"):
    immutableVars.add(newIdentDefs(ident"acceptLanguage", newEmptyNode(), acceptLanguage))
  when defined(napibuild):
    immutableVars.add(newIdentDefs(ident"inCookies", newEmptyNode(), cookiesInVar))
  else:
    if stmtList.isIdentUsed(ident"inCookies"):
      immutableVars.add(newIdentDefs(ident"inCookies", newEmptyNode(), cookiesInVar))
  when exportJvm or defined(napibuild) or exportPython:
    immutableVars.add(newIdentDefs(ident"reqMethod", newEmptyNode(), reqMethod))
  else:
    if stmtList.isIdentUsed(ident"reqMethod"):
      immutableVars.add(newIdentDefs(ident"reqMethod", newEmptyNode(), reqMethod))
  if stmtList.isIdentUsed(ident"headers"):
    immutableVars.add(newIdentDefs(ident"headers", newEmptyNode(), headers))
  when enableLiveViews:
    if stmtList.isIdentUsed(ident"startSession") or stmtList.isIdentUsed(ident"hostname") or liveViewsCache.len > 0:
      immutableVars.add(newIdentDefs(ident"hostname", newEmptyNode(), hostname))
  else:
    if stmtList.isIdentUsed(ident"startSession") or stmtList.isIdentUsed(ident"hostname"):
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
        newNimNode(nnkWhenStmt).add(newNimNode(nnkElifBranch).add(
          newCall("declared", ident"finalizeProgram"),
          newCall("addQuitProc", ident"finalizeProgram"),
        ))
      ),
      nnkProcDef
    ),
    newCall("main")
  )
  result[0].addPragma(ident"gcsafe")


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
  when enableApiDoc:
    var b = body
    var docsData = b.genApiDoc()
  
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
          newProc(ident"renderDocsProcedure", [ident"string"], happyxDocs(docsData))
        else:
          newEmptyNode(),
        when enableApiDoc:
          newProc(ident"openApiJson", [ident"JsonNode"], openApiDocs(docsData))
        else:
          newEmptyNode(),
        newCall("routes", s, body),
        newCall("start", s),
        newNimNode(nnkWhenStmt).add(newNimNode(nnkElifBranch).add(
          newCall("declared", ident"finalizeProgram"),
          newCall("addQuitProc", ident"finalizeProgram"),
        ))
      ),
      nnkProcDef
    ),
    newCall("main")
  )
  result[0].addPragma(ident"gcsafe")

