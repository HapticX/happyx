## # Server
## 
## Provides a Server object that encapsulates the server's address, port, and logger.
## Developers can customize the logger's format using the built-in newConsoleLogger function.
## HappyX provides two options for handling HTTP requests: httpx and asynchttpserver.
## Developers can define which library to use by setting the httpx flag.
## 
## 

import
  macros,
  strutils,
  strtabs,
  strformat,
  asyncdispatch,
  logging,
  terminal,
  colors,
  regex,
  json,
  os,
  ./tag

export
  strutils,
  strtabs,
  strformat,
  asyncdispatch,
  logging,
  terminal,
  colors,
  regex,
  json,
  os


when defined(httpx):
  import
    options,
    httpx
  export
    options,
    httpx
else:
  import asynchttpserver
  export asynchttpserver


type
  Server* = object
    address*: string
    port*: int
    logger*: Logger
    when defined(httpx):
      instance*: Settings
    else:
      instance*: AsyncHttpServer


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


func fgStyled*(text: string, style: Style): string {.inline.} =
  ## This function takes in a string of text and a Style enum
  ## value and returns the same text with the specified style applied.
  ## 
  ## Arguments:
  ## - `text`: A string value representing the text to apply style to.
  ## - `clr`: A Style enum value representing the style to apply to the text.
  ## 
  ## Return value:
  ## - The function returns a string value with the specified style applied to the input text.
  runnableExamples:
    echo fgStyled("Hello, world!", styleBlink)
  ansiStyleCode(style) & text & ansiResetCode


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
  ##   Defaults to `5000`.
  ## 
  ## Returns:
  ## - A new instance of the `Server` object.
  runnableExamples:
    var s = newServer()
    assert s.address == "127.0.0.1"
  result = Server(
    address: address,
    port: port,
    logger: newConsoleLogger(fmtStr=fgColored("[$date at $time]", fgYellow) & ":$levelname - ")
  )
  when defined(httpx):
    result.instance = initSettings(Port(port), bindAddr=address)
  else:
    result.instance = newAsyncHttpServer()
  addHandler(result.logger)


template start*(server: Server): untyped =
  ## The `start` template starts the given server and listens for incoming connections.
  ## Parameters:
  ## - `server`: A `Server` instance that needs to be started.
  ## 
  ## Returns:
  ## - `untyped`: This template does not return any value.
  when defined(debug):
    `server`.logger.log(
      lvlInfo, fmt"Server started at http://{server.address}:{server.port}"
    )
  when not declared(handleRequest):
    proc handleRequest(req: Request) {.async.} =
      discard
  when defined(httpx):
    run(handleRequest, `server`.instance)
  else:
    waitFor `server`.instance.serve(Port(`server`.port), handleRequest, `server`.address)


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
  ## Arguments:
  ##   `req: Request`: An instance of the Request type, representing the request that we are responding to.
  ##   `message: string`: The message that we want to include in the response body.
  ##   `code: HttpCode = Http200`: The HTTP status code that we want to send in the response.
  ##                               This argument is optional, with a default value of Http200 (OK).
  when defined(httpx):
    var headersArr: seq[string] = @[]
    for key, value in headers.pairs():
      headersArr.add(key & ": " & value)
    req.send(code, message, headersArr.join("\r\n"))
  else:
    await req.respond(code, message, headers)


template answerJson*(req: Request, data: untyped, code: HttpCode = Http200,): untyped =
  ## Answers to request with json data
  answer(req, $(%*`data`), code, newHttpHeaders([("Content-Type", "application/json; charset=utf-8")]))


template answerHtml*(req: Request, data: string | TagRef, code: HttpCode = Http200,): untyped =
  ## Answers to request with HTML data
  when data is string:
    let d = data
  else:
    let d = $data
  answer(req, d, code, newHttpHeaders([("Content-Type", "text/html; charset=utf-8")]))


proc parseQuery*(query: string): owned(StringTableRef) =
  ## Parses query and retrieves JSON object
  runnableExamples:
    let
      query = "a=1000&b=8000&password=mystrongpass"
      parsedQuery = parseQuery(query)
    assert parsedQuery["a"] == "1000"
  result = newStringTable()
  for i in query.split('&'):
    let splitted = i.split('=')
    result[splitted[0]] = splitted[1]


proc exportRouteArgs*(urlPath, routePath, body: NimNode): NimNode {.compileTime.} =
  ## Finds and exports route arguments
  let
    elifBranch = newNimNode(nnkElifBranch)
    path = $routePath
  var
    routePathStr = $routePath
    hasChildren = false
  # integer param
  routePathStr = routePathStr.replace(re"\{[a-zA-Z][a-zA-Z0-9_]*:int\}", "(\\d+)")
  # float param
  routePathStr = routePathStr.replace(re"\{[a-zA-Z][a-zA-Z0-9_]*:float\}", "(\\d+\\.\\d+|\\d+)")
  # word param
  routePathStr = routePathStr.replace(re"\{[a-zA-Z][a-zA-Z0-9_]*:word\}", "(\\w+?)")
  # string param
  routePathStr = routePathStr.replace(re"\{[a-zA-Z][a-zA-Z0-9_]*:string\}", "([^/]+?)")
  # path param
  routePathStr = routePathStr.replace(re"\{[a-zA-Z][a-zA-Z0-9_]*:path\}", "([\\S]+)")
  # path param
  routePathStr = routePathStr.replace(re"\{[a-zA-Z][a-zA-Z0-9_]*:/([\s\S]+?)/\}", "($1)")

  let
    regExp = newCall("re", newStrLitNode("^" & routePathStr & "$"))
    found = path.findAll(re"\{([a-zA-Z][a-zA-Z0-9_]*):(int|float|string|path|word|/[\s\S]+?/)\}")
    foundLen = found.len

  elifBranch.add(newCall("contains", urlPath, regExp), body)

  var idx = 0
  for i in found:
    let
      name = ident(i.group(0, path)[0])
      argTypeStr = i.group(1, path)[0]
      argType = ident(argTypeStr)
      letSection = newNimNode(nnkLetSection).add(
        newNimNode(nnkIdentDefs).add(name, newEmptyNode())
      )
      foundGroup = newNimNode(nnkBracketExpr).add(
        newCall(
          "group",
          newNimNode(nnkBracketExpr).add(ident("founded_regexp_matches"), newIntLitNode(0)),
          newIntLitNode(idx),  # group index,
          urlPath
        ),
        newIntLitNode(0)
      )
    case argTypeStr:
    of "int":
      letSection[0].add(newCall("parseInt", foundGroup))
    of "float":
      letSection[0].add(newCall("parseFloat", foundGroup))
    of "path", "string", "word":
      letSection[0].add(foundGroup)
    else:
      # regex
      letSection[0].add(foundGroup)
    elifBranch[1].insert(0, letSection)
    hasChildren = true
    inc idx
  
  if hasChildren:
    elifBranch[1].insert(
      0, newNimNode(nnkLetSection).add(
        newIdentDefs(
          ident("founded_regexp_matches"), newEmptyNode(), newCall("findAll", urlPath, regExp)
        )
      )
    )
    return elifBranch
  return newEmptyNode()


macro routes*(server: Server, body: untyped): untyped =
  ## You can create routes with this marco
  ## 
  ## #### Available Path Params
  ## - `int`: any integer.
  ## - `float`: any float number.
  ## - `word`: any word includes `re"\w+"`.
  ## - `string`: any string excludes `"/"`.
  ## - `path`: any float number includes `"/"`.
  ## 
  ## #### Available Route Types
  ## - `"/path/with/{args:path}"` - Just string with route path. Matches any request method
  ## - `get "/path/{args:word}"` - Route with request method. Method can be`get`, `post`, `patch`, etc.
  ## - `notfound` - Route that matches when no other matched.
  ## - `middleware` - Always executes first.
  ## 
  runnableExamples:
    var myServer = newServer()
    myServer.routes:
      "/":
        req.answer "root"
      "/user{id:int}":
        req.answer fmt"hello, user {id}!"
      middleware:
        echo req
      notfound:
        req.answer "Oops! Not found!"
  var
    stmtList = newStmtList()
    ifStmt = newNimNode(nnkIfStmt)
    notFoundNode = newEmptyNode()
    procStmt = newProc(
      ident("handleRequest"),
      [newEmptyNode(), newIdentDefs(ident("req"), ident("Request"))],
      stmtList
    )
  when defined(httpx):
    var path = newCall("get", newCall("path", ident("req")))
    let
      reqMethod = newCall("get", newDotExpr(ident("req"), ident("httpMethod")))
      reqMethodStringify = newCall("$", reqMethod)
      reqMethodStr = "req.httpMethod"
  else:
    var path = newDotExpr(newDotExpr(ident("req"), ident("url")), ident("path"))
    let
      reqMethod = newDotExpr(ident("req"), ident("reqMethod"))
      reqMethodStringify = newCall("$", reqMethod)
      reqMethodStr = "req.reqMethod"
  let directoryFromPath = newCall(
    "&",
    newStrLitNode("."),
    newCall("replace", path, newLit('/'), ident("DirSep"))
  )
  
  procStmt.addPragma(ident("async"))
  
  for statement in body:
    if statement.kind in [nnkCall, nnkCommand]:
      # "/...": statement list
      if statement[1].kind == nnkStmtList and statement[0].kind == nnkStrLit:
        var exported = exportRouteArgs(path, statement[0], statement[1])
        if exported.len > 0:  # /my/path/with{custom:int}/{param:path}
          ifStmt.add(exported)
        else:  # /just-my-path
          ifStmt.add(newNimNode(nnkElifBranch).add(
            newCall("==", path, statement[0]), statement[1]
          ))
      # notfound: statement list
      elif statement[1].kind == nnkStmtList and statement[0].kind == nnkIdent:
        let name = $statement[0]
        if name == "notfound":
          notFoundNode = statement[1]
        elif name == "middleware" and statement.len == 2:
          stmtList.insert(0, statement[1])
      # reqMethod("/..."):
      #   ...
      elif statement[0].kind == nnkIdent and statement[1].kind == nnkStrLit:
        let name = ($statement[0]).toUpper()
        if name == "STATICDIR":
          ifStmt.insert(
            0, newNimNode(nnkElifBranch).add(
              newCall(
                "or",
                newCall("startsWith", path, statement[1]),
                newCall("startsWith", path, newStrLitNode("/" & $statement[1])),
              ),
              newStmtList().add(
                newVarStmt(
                  ident("content"),
                  newCall("readFile", directoryFromPath)
                ),
                newCall("answer", ident("req"), ident("content"))
              )
            )
          )
          continue
        var exported = exportRouteArgs(path, statement[1], statement[2])
        if exported.len > 0:  # /my/path/with{custom:int}/{param:path}
          exported[0] = newCall("and", exported[0], newCall("==", reqMethodStringify, newStrLitNode(name)))
          ifStmt.add(exported)
        else:  # /just-my-path
          ifStmt.add(newNimNode(nnkElifBranch).add(
            newCall(
              "and",
              newCall("==", path, statement[1]),
              newCall("==", reqMethodStringify, newStrLitNode(name))
            ),
            statement[2]
          ))

  # urlPath
  stmtList.insert(
    0, newNimNode(nnkLetSection).add(
      newIdentDefs(ident("urlPath"), newEmptyNode(), path),
      newIdentDefs(ident("reqMethod"), newEmptyNode(), reqMethod),
    )
  )
  
  when defined(debug):
    stmtList.add(newCall(
      "log",
      newDotExpr(server, ident("logger")),
      ident("lvlInfo"),
      newCall("fmt", newStrLitNode("{" & reqMethodStr & "}::{urlPath}"))
    ))

  if ifStmt.len > 0:
    stmtList.add(ifStmt)
    # return 404
    if notFoundNode.kind == nnkEmpty:
      ifStmt.add(newNimNode(nnkElse).add(
        newCall(ident("answer"), ident("req"), newStrLitNode("Not found"), ident("Http404")))
      )
    else:
      ifStmt.add(newNimNode(nnkElse).add(notFoundNode))
  else:
    # return 404
    if notFoundNode.kind == nnkEmpty:
      stmtList.add(newCall(ident("answer"), ident("req"), newStrLitNode("Not found"), ident("Http404")))
    else:
      stmtList.add(notFoundNode)
  procStmt
