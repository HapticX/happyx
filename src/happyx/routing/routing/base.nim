import
  std/macros,
  std/macrocache,
  std/strutils,
  std/strformat,
  ../../private/scanutils,
  ../../core/[exceptions, constants],
  ./types,
  ./scanfuncs


const
  declaredPathParams* = CacheTable"HappyXDeclaredPathParams"
  onException* = CacheTable"HappyXOnException"


static:
  onException["e"] = newStmtList()


proc handleRoute*(route: string): RouteDataObj =
  ## Handles route and receive route data object.
  ## 
  ## ## Examples
  ## 
  ## dollar full: `$argument?:word=hello`
  ## curly full: `{argument?:word=hello}`
  ## model full: `[argument:ModelName:json]`
  ## 
  result = RouteDataObj(path: route, pathParams: @[], requestModels: @[])
  
  var purePath: string = ""

  for p in route.findParams(purePath):
    result.pathParams.add(newPathParamObj(p.name, p.kind, p.def, p.opt))
    
  for m in route.findModels():
    result.requestModels.add(newRequestModelObj(m.name, m.kind, m.mode))
  if purePath.startsWith("//"):
    purePath = purePath[1..^1]
  result.purePath = purePath


proc getDefaultValue(kind, value: string): NimNode =
  case kind
  of "string", "word", "path":
    newLit(value)
  of "int":
    newLit(parseInt(value))
  of "float":
    newLit(parseFloat(value))
  of "bool":
    newLit(parseBool(value))
  else:
    if kind.startsWith("enum"):
      ident(value)
    else:
      newEmptyNode()


proc exportRouteArgs*(urlPath, routePath, body: NimNode): NimNode =
  ## Finds and exports route arguments
  var path = $routePath
  # Find all declared path params
  for part in path.split("/"):
    var name: string
    if scanf(part, "<$w>$.", name):
      if declaredPathParams.hasKey(name):
        path = path.replace(fmt"<{name}>", $declaredPathParams[name])
      else:
        throwDefect(
          HpxPathParamDefect,
          "Unknown path param name: " & name & "\n" & $routePath.toStrLit,
          lineInfoObj(routePath)
        )
  var
    routeData =
      when not exportPython and not defined(napibuild) and not exportJvm:
        handleRoute(path)
      else:
        RouteDataObj.default
    hasChildren = false
  let
    elifBranch = newNimNode(nnkElifBranch)
    scanStmt = newCall("scanf", urlPath, newLit(routeData.purePath & "$."))
    condition = newStmtList()

  for i in routeData.pathParams:
    condition.add(
      if i.defaultValue.len > 0:
        newNimNode(nnkVarSection).add(
          newIdentDefs(
            ident(i.name),
            ident(i.paramType.kind2tp),
            getDefaultValue(i.paramType, i.defaultValue)
          )
        )
      else:
        newNimNode(nnkVarSection).add(
          newIdentDefs(ident(i.name), ident(i.paramType.kind2tp), newEmptyNode())
        )
    )
    scanStmt.add(ident(i.name))
    hasChildren = true
  
  condition.add(scanStmt)
  elifBranch.add(condition)
  elifBranch.add(body)

  let reqBody =
    when enableHttpBeast or enableHttpx or enableBuiltin:
      newCall("get", newDotExpr(ident"req", ident"body"))
    else:
      newDotExpr(ident"req", ident"body")

  # Models
  for i in routeData.requestModels:
    elifBranch[1].insert(
      0,
      newNimNode(nnkVarSection).add(
        newIdentDefs(
          ident(i.name),
          newEmptyNode(),
          case i.target.toLower():
          of "json":
            newNimNode(nnkTryStmt).add(
              newCall("jsonTo" & i.typeName, newCall("parseJson", reqBody))
            ).add(newNimNode(nnkExceptBranch).add(
              ident"JsonParsingError",
              newStmtList(
                when enableDebug:
                  newCall("echo", newCall("fmt", newLit"json parse error: {getCurrentExceptionMsg()}"))
                else:
                  newEmptyNode(),
                onException["e"],
                newCall(
                  "answerJson",
                  ident"req",
                  parseExpr"""{"response": "Incorrect JSON structure"}""",
                  ident"Http400"
                ),
                newNimNode(nnkReturnStmt).add(newEmptyNode()),
                newCall("jsonTo" & i.typeName, newCall("newJObject"))
              )
            )).add(newNimNode(nnkExceptBranch).add(
              ident"JsonKindError",
              newStmtList(
                when enableDebug:
                  newCall("echo", newCall("fmt", newLit"json kind error: {getCurrentExceptionMsg()}"))
                else:
                  newEmptyNode(),
                onException["e"],
                newCall(
                  "answerJson",
                  ident"req",
                  parseExpr"""{"response": "Incorrect JSON structure (wrong kind)"}""",
                  ident"Http400"
                ),
                newNimNode(nnkReturnStmt).add(newEmptyNode()),
                newCall("jsonTo" & i.typeName, newCall("newJObject"))
              )
            ), newNimNode(nnkExceptBranch).add(
              ident"Exception",
              newStmtList(
                when enableDebug:
                  newCall("echo", newCall("fmt", newLit"json unknown error: {getCurrentExceptionMsg()}"))
                else:
                  newEmptyNode(),
                onException["e"],
                newCall(
                  "answerJson",
                  ident"req",
                  parseExpr"""{"response": "Unknown JSON structure"}""",
                  ident"Http400"
                ),
                newNimNode(nnkReturnStmt).add(newEmptyNode()),
                newCall("jsonTo" & i.typeName, newCall("newJObject"))
              )
            ))
          of "urlencoded", "x-www-form-urlencoded", "xwwwformurlencoded":
            newCall("xWwwUrlencodedTo" & i.typeName, reqBody)
          of "form-data", "formdata":
            newCall("formDataTo" & i.typeName, reqBody)
          of "xml":
            newCall("xmlBodyTo" & i.typeName, reqBody)
          else:
            newCall("jsonTo" & i.typeName, newCall("newJObject"))
        )
      )
    )
    hasChildren = true

  if hasChildren:
    when enableRoutingDebugMacro:
      echo elifBranch.toStrLit
    return elifBranch
  return newEmptyNode()
