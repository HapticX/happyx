import
  std/macros,
  std/strformat,
  std/httpcore,
  std/tables,
  std/strutils,
  ../../../private/macro_utils,
  ../../routing,
  ../base


type
  CachedResult* = object
    cachedData*: string
    cachedHeaders*: HttpHeaders
    cachedStatusCode*: HttpCode
  CachedRoute* = object
    create_at*: float
    cachedResult*: CachedResult


var cachedRoutes* {.threadvar.}: Table[string, CachedRoute]
cachedRoutes = initTable[string, CachedRoute]()


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
  regDecorator("Cached", cachedDecoratorImpl)
