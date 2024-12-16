## # Decorators 🔌
## 
## Provides convenient wrapper to create route decorators
## 
## > It can be used for plugins also
## 
## ## Decorator Usage Example ✨
## 
## 
## .. code-block:: nim
##    serve ...:
##      @AuthBasic
##      get "/":
##        # password and username takes from header "Authorization"
##        # Authorization: Bearer BASE64
##        echo username
##        echo password
## 
## 
## ## Own decorators
## 
## 
## .. code-block:: nim
##    proc myDecorator(httpMethods: seq[string], routePath: string, statementList: NimNode) =
##      statementList.insert(0, newCall("echo", newLit"My own decorator"))
##    # Register decorator
##    static:
##      regDecorator("MyDecorator", myDecorator)
##    # Use it
##    serve ...:
##      @MyDecorator
##      get "/":
## 
import
  std/macros,
  std/tables,
  std/strformat,
  std/strutils,
  std/base64,
  std/httpcore,
  ../core/constants,
  ../private/macro_utils,
  ./routing


export base64


type
  DecoratorImpl* = proc(
    httpMethods: seq[string],
    routePath: string,
    statementList: NimNode,
    arguments: seq[NimNode]
  )
  CachedResult* = object
    data*: string
    headers*: HttpHeaders
    statusCode*: HttpCode
  CachedRoute* = object
    create_at*: float
    res*: CachedResult


var decorators* {.compileTime.} = newTable[string, DecoratorImpl]()


proc regDecorator*(decoratorName: string, decorator: DecoratorImpl) {.compileTime.} =
   decorators[decoratorName] = decorator


macro decorator*(name, body: untyped): untyped =
  let decoratorImpl = $name & "Impl"
  newStmtList(
    newProc(
      postfix(ident(decoratorImpl), "*"),
      [
        newEmptyNode(),
        newIdentDefs(ident"httpMethods", newNimNode(nnkBracketExpr).add(ident"seq", ident"string")),
        newIdentDefs(ident"routePath", ident"string"),
        newIdentDefs(ident"statementList", ident"NimNode"),
        newIdentDefs(ident"arguments", newNimNode(nnkBracketExpr).add(ident"seq", ident"NimNode")),
      ],
      body
    ),
    newNimNode(nnkStaticStmt).add(
      newCall("regDecorator", newLit($name), ident(decoratorImpl))
    )
  )


when enableDefaultDecorators:
  var cachedRoutes* {.threadvar.}: Table[string, CachedRoute]
  cachedRoutes = initTable[string, CachedRoute]()

  proc authBasicDecoratorImpl(httpMethods: seq[string], routePath: string, statementList: NimNode, arguments: seq[NimNode]) =
    statementList.insert(0, parseStmt"""
var (username, password) = ("", "")
if not headers.hasKey("Authorization"):
  var statusCode = 401
  return {"response": "failure", "reason": "You should to use Basic authorization!"}
else:
  (username, password) = block:
    let code = headers["Authorization"].split(" ")[1]
    let decoded = base64.decode(code).split(":", 1)
    (decoded[0], decoded[1])"""
    )
  

  proc authBearerJwtDecoratorImpl(httpMethods: seq[string], routePath: string, statementList: NimNode, arguments: seq[NimNode]) =
    let variableName = if arguments.len > 0: arguments[0] else: ident"jwtToken"
    statementList.insert(0, parseStmt(fmt"""
var {variableName}: TableRef[system.string, claims.Claim]
if not headers.hasKey("Authorization"):
  var statusCode = 401
  return {{"response": "failure", "reason": "You should to be authorized!"}}
else:
  if headers["Authorization"].startsWith("Bearer "):
    {variableName} = headers["Authorization"][7..^1].toJWT.claims
  else:
    var statusCode = 401
    return {{"response": "failure", "reason": "You should to be authorized!"}}""")
    )
  

  proc authJwtDecoratorImpl(httpMethods: seq[string], routePath: string, statementList: NimNode, arguments: seq[NimNode]) =
    let variableName = if arguments.len > 0: arguments[0] else: ident"jwtToken"
    statementList.insert(0, parseStmt(fmt"""
var {variableName}: TableRef[system.string, claims.Claim]
if not headers.hasKey("Authorization"):
  var statusCode = 401
  return {{"response": "failure", "reason": "You should to be authorized!"}}
else:
  {variableName} = headers["Authorization"].toJWT.claims""")
    )


  proc getUserAgentDecoratorImpl(httpMethods: seq[string], routePath: string, statementList: NimNode, arguments: seq[NimNode]) =
    statementList.insert(0, parseStmt"""
var userAgent = navigator.userAgent
"""
    )


  proc cachedDecoratorImpl(httpMethods: seq[string], routePath: string, statementList: NimNode, arguments: seq[NimNode]) =
    let
      route = handleRoute(routePath)
      purePath = route.purePath.replace('{', '_').replace('}', '_')

    let expiresIn =
      if arguments.len == 1:
        arguments[0]
      else:
        newLit(60)
    
    var routeKey = fmt"{purePath}:pp("
    for i in route.pathParams:
      routeKey &= i.name & "={" & i.name & "}"
    routeKey &= ")"
    echo routeKey

    let
      queryStmt = newStmtList()
      queryArrStmt = newStmtList()

    if statementList.isIdentUsed(ident"query"):
      var usages = statementList.getIdentUses(ident"query")
      for i in usages:
        if i.kind == nnkInfix and i[0] == ident"?" and i[1] == ident"query" and i[2].kind == nnkIdent:
          queryStmt.add parseStmt(fmt"""routeKey &= "{i[2]}" & "=" & query.getOrDefault("{i[2]}", "")""")
        elif i.kind == nnkBracketExpr and i[0] == ident"query" and i[1].kind == nnkStrLit:
          queryStmt.add parseStmt(fmt"""routeKey &= "{i[1].strVal}" & "=" & query.getOrDefault("{i[1].strVal}", "")""")
        elif i.kind == nnkBracketExpr and i[0] == ident"query":
          queryStmt.add parseStmt(fmt"""routeKey &= {i[1].toStrLit} & "=" & query.getOrDefault({i[1].toStrLit}, "")""")
        else:
          discard
          # echo i.treeRepr
    if statementList.isIdentUsed(ident"queryArr"):
      var usages = statementList.getIdentUses(ident"queryArr")
      for i in usages:
        if i.kind == nnkInfix and i[0] == ident"?" and i[1] == ident"queryArr" and i[2].kind == nnkIdent:
          queryStmt.add parseStmt(fmt"""routeKey &= "{i[2]}" & "=" & $queryArr.getOrDefault("{i[2]}", "")""")
        elif i.kind == nnkBracketExpr and i[0] == ident"queryArr" and i[1].kind == nnkStrLit:
          queryStmt.add parseStmt(fmt"""routeKey &= "{i[1].strVal}" & "=" & $queryArr.getOrDefault("{i[1].strVal}", "")""")
        elif i.kind == nnkBracketExpr and i[0] == ident"queryArr":
          queryStmt.add parseStmt(fmt"""routeKey &= {i[1].toStrLit} & "=" & $queryArr.getOrDefault({i[1].toStrLit}, "")""")
        else:
          discard
          # echo i.treeRepr

    let cachedRoutesResult = newNimNode(nnkDotExpr).add(
      newNimNode(nnkBracketExpr).add(ident"cachedRoutes", ident"routeKey"), ident"res"
    )
    let cachedRoutesCreateAt = newNimNode(nnkDotExpr).add(
      newNimNode(nnkBracketExpr).add(ident"cachedRoutes", ident"routeKey"), ident"create_at"
    )

    statementList.insert(0, newStmtList(
      newVarStmt(ident"routeKey", newCall("fmt", newLit(fmt"{routeKey}"))),
      queryStmt,
      queryArrStmt,
      newConstStmt(ident"thisRouteCanBeCached", newLit(true)),
      newNimNode(nnkIfStmt).add(newNimNode(nnkElifBranch).add(
        newCall("hasKey", ident"cachedRoutes", ident"routeKey"),
        newNimNode(nnkIfStmt).add(newNimNode(nnkElifBranch).add(
          newCall("<", newCall("-", newCall("cpuTime"), cachedRoutesCreateAt), expiresIn),
          newStmtList(
            newConstStmt(ident"thisIsCachedResponse", newLit(true)),
            newCall(
              "answer",
              ident"req",
              newNimNode(nnkDotExpr).add(cachedRoutesResult, ident"data"),
              newNimNode(nnkDotExpr).add(cachedRoutesResult, ident"statusCode"),
              newNimNode(nnkDotExpr).add(cachedRoutesResult, ident"headers"),
            ),
            newNimNode(nnkBreakStmt).add(ident"__handleRequestBlock")
          )
        )),
      )),
    ))


  static:
    regDecorator("AuthBasic", authBasicDecoratorImpl)
    regDecorator("AuthBearerJWT", authBearerJwtDecoratorImpl)
    regDecorator("AuthJWT", authJwtDecoratorImpl)
    regDecorator("GetUserAgent", getUserAgentDecoratorImpl)
    regDecorator("Cached", cachedDecoratorImpl)
