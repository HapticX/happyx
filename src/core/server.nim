#[
  Provides working with server
]#
import
  macros,
  strutils,
  asyncdispatch,
  strtabs,
  logging,
  terminal,
  colors,
  uri,
  regex


when defined(httpx):
  import httpx
else:
  import asynchttpserver


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
  ansiForegroundColorCode(clr) & text & ansiResetCode


proc newServer*(address: string = "127.0.0.1", port: int = 5000): Server =
  ## Initializes a new Server object
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
  when defined(debug):
    server.logger.log(
      lvlInfo, fmt"Server started at http://{server.address}:{server.port}"
    )
  when defined(httpx):
    run(handleRequest, server.instance)
  else:
    waitFor server.instance.serve(Port(server.port), handleRequest, server.address)


template answer*(req: Request, message: string, code: HttpCode = Http200) =
  ## Answers to the request
  ## 
  ## Arguments:
  ##   `req: Request`: An instance of the Request type, representing the request that we are responding to.
  ##   `message: string`: The message that we want to include in the response body.
  ##   `code: HttpCode = Http200`: The HTTP status code that we want to send in the response.
  ##                               This argument is optional, with a default value of Http200 (OK).
  when defined(httpx):
    req.send(code, message, "Content-type: text/plain; charset=utf-8")
  else:
    await req.respond(
      code,
      message,
      {
        "Content-type": "text/plain; charset=utf-8"
      }.newHttpHeaders()
    )


func parseQuery*(query: string): owned(StringTableRef) =
  ## Parses query and retrieves JSON object
  runnableExamples:
    let
      query = "a=1000&b=8000&password=mystrongpass"
      parsedQuery = parseQuery(query)
    assert parseQuery["a"] == "1000"
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
  routePathStr = routePathStr.replace(re"\{[a-zA-Z][a-zA-Z0-9_]*:int\}", "(\\d+)")
  routePathStr = routePathStr.replace(re"\{[a-zA-Z][a-zA-Z0-9_]*:float\}", "(\\d+\\.\\d+)")
  routePathStr = routePathStr.replace(re"\{[a-zA-Z][a-zA-Z0-9_]*:string\}", "([^/]+?)")
  routePathStr = routePathStr.replace(re"\{[a-zA-Z][a-zA-Z0-9_]*:path\}", "([\\S]+)")

  let
    regExp = newCall("re", newStrLitNode(routePathStr))
    found = path.findAll(re"\{([a-zA-Z][a-zA-Z0-9_]*):(int|float|string|path)\}")
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
    of "path", "string":
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
  var
    stmtList = newStmtList()
    ifStmt = newNimNode(nnkIfStmt)
    procStmt = newProc(
      ident("handleRequest"),
      [newEmptyNode(), newIdentDefs(ident("req"), ident("Request"))],
      stmtList
    )
  when defined(httpx):
    var path = newCall("get", newCall("path", ident("req")))
  else:
    var path = newDotExpr(newDotExpr(ident("req"), ident("url")), ident("path"))
  
  procStmt.addPragma(ident("async"))
  
  for statement in body:
    if statement.kind == nnkCall:
      # "/...": statement list
      if statement[1].kind == nnkStmtList and statement[0].kind == nnkStrLit:
        var exported = exportRouteArgs(path, statement[0], statement[1])
        if exported.len > 0:  # /my/path/with{custom:int}/{param:path}
          ifStmt.add(exported)
        else:  # just my path
          ifStmt.add(newNimNode(nnkElifBranch).add(
            newCall("==", path, statement[0]), statement[1]
          ))
      # notfound: statement list
      elif statement[1].kind == nnkStmtList and statement[0].kind == nnkIdent:
        let name = $statement[0]
        if name == "notfound":
          ifStmt.add(newNimNode(nnkElse).add(statement[1]))
      # func("/..."): statement list
      else:
        let
          name = $statement[0]
          arg = statement[1]
        if name == "route":
          var exported = exportRouteArgs(path, statement[0], statement[1])
          if exported.len > 0:  # /my/path/with{custom:int}/{param:path}
            ifStmt.add(exported)
          else:  # just my path
            ifStmt.add(newNimNode(nnkElifBranch).add(
              newCall("==", path, arg), statement[2]
            ))
  
  stmtList.add(newNimNode(nnkLetSection).add(newIdentDefs(ident("urlPath"), newEmptyNode(), path)))
  when defined(debug):
    when defined(httpx):
      let reqMethod = "req.httpMethod"
    else:
      let reqMethod = "req.reqMethod"
    stmtList.add(newCall(
      "log",
      newDotExpr(ident("server"), ident("logger")),
      ident("lvlInfo"),
      newCall("fmt", newStrLitNode("{" & reqMethod & "}::{urlPath}"))
    ))

  if ifStmt.len > 0:
    stmtList.add(ifStmt)
  else:
    stmtList.add(newCall(ident("answer"), ident("req"), newStrLitNode("Not found")))
  procStmt
