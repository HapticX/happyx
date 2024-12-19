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
    cachedData*: string
    cachedHeaders*: HttpHeaders
    cachedStatusCode*: HttpCode
  CachedRoute* = object
    create_at*: float
    cachedResult*: CachedResult
  RateLimitInfo* = object
    amount*: int
    update_at*: float


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

  var rateLimits* {.threadvar.}: Table[string, RateLimitInfo]
  rateLimits = initTable[string, RateLimitInfo]()

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


  proc rateLimitDecoratorImpl(httpMethods: seq[string], routePath: string, statementList: NimNode, arguments: seq[NimNode]) =
    var
      fromAll = true
      perSecond = 60

    const intLits = { nnkIntLit..nnkInt64Lit }
    let boolean = [newLit(true), newLit(false)]

    for argument in arguments:
      if argument.kind == nnkExprEqExpr and argument[0] == ident"fromAll" and argument[1] in boolean:
        fromAll = argument[1].boolVal
      elif argument.kind == nnkExprEqExpr and argument[0] == ident"perSecond" and argument[1].kind in intLits:
        perSecond = argument[1].intVal.int

    statementList.insert(0, parseStmt(fmt"""
let key =
  when {not fromAll}:
    if hostname != "":
      hostname & "{routePath}"
    elif headers.hasKey("X-Forwarded-For"):
      headers["X-Forwarded-For"].split(",", 1)[0] & "{routePath}"
    elif headers.hasKey("X-Real-Ip"):
      headers["X-Real-Ip"] & "{routePath}"
    else:
      "{routePath}"
  else:
    "{routePath}"
if not rateLimits.hasKey(key):
  rateLimits[key] = RateLimitInfo(amount: 1, update_at: cpuTime())
elif cpuTime() - rateLimits[key].update_at < 1.0:
  inc rateLimits[key].amount
else:
  rateLimits[key].update_at = cpuTime()
  rateLimits[key].amount = 1

if rateLimits[key].amount > {perSecond}:
  var statusCode = 429
  return "Too many requests"
""")
    )


  proc cachedDecoratorImpl(httpMethods: seq[string], routePath: string, statementList: NimNode, arguments: seq[NimNode]) =
    let
      route = handleRoute(routePath)
      purePath = route.purePath.replace('{', '_').replace('}', '_')

    let expiresIn =
      if arguments.len == 1 and arguments[0].kind in { nnkIntLit..nnkInt64Lit }:
        newLit(arguments[0].intVal.int)
      elif arguments.len == 1 and arguments[0].kind == nnkExprEqExpr and arguments[0][0] == ident"expires":
        if arguments[0][1].kind in { nnkIntLit..nnkInt64Lit }:
          newLit(arguments[0][1].intVal.int)
        else:
          newLit(60)
      else:
        newLit(60)
    
    var routeKey = fmt"{purePath}("
    for i in route.pathParams:
      routeKey &= i.name & "={" & i.name & "}"
    for i in route.requestModels:
      routeKey &= i.name & "={" & i.name & ".repr}"
    routeKey &= ")"

    let queryStmt = newStmtList()
    var usedVariables: seq[NimNode] = @[]

    for identName in ["query", "queryArr"]:
      let idnt = ident(identName)
      if statementList.isIdentUsed(idnt):
        var usages = statementList.getIdentUses(idnt)
        for i in usages:
          # query?KEY
          if i.kind == nnkInfix and i[0] == ident"?" and i[1] == idnt and i[2].kind == nnkIdent:
            if i[2] notin usedVariables:
              queryStmt.add parseStmt(
                fmt"""routeKey &= "{i[2]}" & "=" & {identName}.getOrDefault("{i[2]}", "")"""
              )
              usedVariables.add i[2]
          # query["KEY"]
          elif i.kind == nnkBracketExpr and i[0] == idnt and i[1].kind == nnkStrLit:
            if i[1] notin usedVariables:
              queryStmt.add parseStmt(
                fmt"""routeKey &= "{i[1].strVal}" & "=" & {identName}.getOrDefault("{i[1].strVal}", "")"""
              )
              usedVariables.add i[1]
          # query[KEY]
          elif i.kind == nnkBracketExpr and i[0] == idnt:
            if i[1] notin usedVariables:
              queryStmt.add parseStmt(
                fmt"""routeKey &= {i[1].toStrLit} & "=" & {identName}.getOrDefault({i[1].toStrLit}, "")"""
              )
              usedVariables.add i[1]
          # hasKey(query, KEY)
          elif i.kind == nnkCall and i[0] == ident"hasKey" and i[1] == idnt and i.len == 3:
            if i[2] notin usedVariables:
              queryStmt.add parseStmt(
                fmt"""routeKey &= {i[2].toStrLit} & "=" & {identName}.getOrDefault({i[2].toStrLit}, "")"""
              )
              usedVariables.add i[2]

    let cachedRoutesResult = newNimNode(nnkDotExpr).add(
      newNimNode(nnkBracketExpr).add(ident"cachedRoutes", ident"routeKey"), ident"cachedResult"
    )
    let cachedRoutesCreateAt = newNimNode(nnkDotExpr).add(
      newNimNode(nnkBracketExpr).add(ident"cachedRoutes", ident"routeKey"), ident"create_at"
    )

    statementList.insert(0, newStmtList(
      newVarStmt(ident"routeKey", newCall("fmt", newLit(fmt"{routeKey}"))),
      queryStmt,
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
              newNimNode(nnkDotExpr).add(cachedRoutesResult, ident"cachedData"),
              newNimNode(nnkDotExpr).add(cachedRoutesResult, ident"cachedStatusCode"),
              newNimNode(nnkDotExpr).add(cachedRoutesResult, ident"cachedHeaders"),
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
    regDecorator("RateLimit", rateLimitDecoratorImpl)
