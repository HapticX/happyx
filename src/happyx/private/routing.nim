import
  # stdlib
  strformat,
  strutils,
  strtabs,
  tables,
  macros,
  # deps
  regex,
  # happyx
  ./exceptions,
  ./macro_utils


var
  declaredPathParams* {. compileTime .} = newStringTable()


proc exportRouteArgs*(urlPath, routePath, body: NimNode): NimNode {.compileTime.} =
  ## Finds and exports route arguments
  ## 
  ## [Read more about it](/happyx/happyx/routing.html)
  let
    elifBranch = newNimNode(nnkElifBranch)
    dollarToCurve = re"\$([^:\/\{\}]+)(:\w+)?(\[m\])?(=[^\/\{\}]+)?(m)?"
    defaultWithoutQuestion = re"\{([^:\/\{\}\?]+)(:\w+)?(\[m\])?(=[^\/\{\}]+)\}"
  var
    path = $routePath
    hasChildren = false
  # Find all declared path params
  for i in path.findAll(re"<([a-zA-Z][a-zA-Z0-9_]*)>"):
    let name = i.group(0, path)[0]
    if declaredPathParams.hasKey(name):
      path = path.replace(fmt"<{name}>", declaredPathParams[name])
    else:
      throwDefect(
        InvalidPathParamDefect,
        "Unknown path param name: " & name & "\n" & $routePath.toStrLit,
        lineInfoObj(routePath)
      )
  # adaptive $params and repair default params
  path = path.replace(dollarToCurve, "{$1$2$3$4}")
  path = path.replace(defaultWithoutQuestion, "{$1?$2$3$4}")
  var routePathStr = path
  # boolean param
  routePathStr = routePathStr.replace(re"\{[a-zA-Z][a-zA-Z0-9_]*(\??):bool(\[m\])?(=\S+?)?\}", "(n|y|no|yes|true|false|1|0|on|off)$1")
  # integer param
  routePathStr = routePathStr.replace(re"\{[a-zA-Z][a-zA-Z0-9_]*(\??):int(\[m\])?(=\S+?)?\}", "(\\d+)$1")
  # float param
  routePathStr = routePathStr.replace(re"\{[a-zA-Z][a-zA-Z0-9_]*(\??):float(\[m\])?(=\S+?)?\}", "(\\d+\\.\\d+|\\d+)$1")
  # word param
  routePathStr = routePathStr.replace(re"\{[a-zA-Z][a-zA-Z0-9_]*(\??):word(\[m\])?(=\S+?)?\}", "(\\w+)$1")
  # string param
  routePathStr = routePathStr.replace(re"\{[a-zA-Z][a-zA-Z0-9_]*(\??):string(\[m\])?(=\S+?)?\}", "([^/]+)$1")
  routePathStr = routePathStr.replace(re"\{[a-zA-Z][a-zA-Z0-9_]*(\??)(\[m\])?(=\S+?)?\}", "([^/]+)$1")
  # path param
  routePathStr = routePathStr.replace(re"\{[a-zA-Z][a-zA-Z0-9_]*:path(\[m\])?\}", "([\\S]+)")
  # regex param
  routePathStr = routePathStr.replace(re"\{[a-zA-Z][a-zA-Z0-9_]*:/([\s\S]+?)/(\[m\])?\}", "($1)")
  # Remove models
  routePathStr = routePathStr.replace(re"\[[a-zA-Z][a-zA-Z0-9_]*:[a-zA-Z][a-zA-Z0-9_]*(\[m\])?\]", "")
  let
    regExp = newCall("re", newStrLitNode("^" & routePathStr & "$"))
    found = path.findAll(
      re"\{([a-zA-Z][a-zA-Z0-9_]*\??)(:(bool|int|float|string|path|word|/[\s\S]+?/))?(\[m\])?(=(\S+?))?\}"
    )
    foundModels = path.findAll(
      re"\[([a-zA-Z][a-zA-Z0-9_]*):([a-zA-Z][a-zA-Z0-9_]*)(\[m\])?\]"
    )
  elifBranch.add(newCall("contains", urlPath, regExp), body)
  var
    idx = 0
    name = ""
    isOptional = false
    defaultVal = ""
    isMutable = false
  for i in found:
    # clean
    name = i.group(0, path)[0]
    isOptional = false
    defaultVal =
      if i.group(5, path).len == 0:
        ""
      else:
        i.group(5, path)[0]
    isMutable = i.group(3, path).len != 0
    # detect optional
    if name.endsWith(re"\?"):
      name = name[0..^2]
      isOptional = true
    elif defaultVal.len > 0:
      isOptional = true
    let
      argTypeStr =
        if i.group(2, path).len == 0:
          "string"
        else:
          i.group(2, path)[0]
      letSection = newNimNode(if isMutable: nnkVarSection else: nnkLetSection).add(
        newNimNode(nnkIdentDefs).add(ident(name), newEmptyNode())
      )
      group = newCall(
        "group",
        newNimNode(nnkBracketExpr).add(ident("founded_regexp_matches"), newIntLitNode(0)),
        newIntLitNode(idx),  # group index,
        urlPath
      )
      foundGroup = newNimNode(nnkBracketExpr).add(group, newIntLitNode(0))
      # _groupLen < 1
      conditionOptional = newCall("<", newCall("len", group), newIntLitNode(1))
      # _foundGroupLen == 0
      conditionSecondOptional = newCall("==", newCall("len", foundGroup), newIntLitNode(0))

    if isOptional:
      case argTypeStr:
      of "bool":
        letSection[0].add(newNimNode(nnkIfStmt).add(
            newNimNode(nnkElifBranch).add(
              conditionOptional,
              newLit(
                if defaultVal == "": false else: parseBool(defaultVal)
              )
            ),
            newNimNode(nnkElifBranch).add(
              conditionSecondOptional,
              newLit(
                if defaultVal == "": false else: parseBool(defaultVal)
              )
            ),
            newNimNode(nnkElse).add(newCall("parseBool", foundGroup))
          )
        )
      of "int":
        letSection[0].add(newNimNode(nnkIfStmt).add(
            newNimNode(nnkElifBranch).add(
              conditionOptional,
              newLit(
                if defaultVal == "": 0 else: parseInt(defaultVal)
              )
            ),
            newNimNode(nnkElifBranch).add(
              conditionSecondOptional,
              newLit(
                if defaultVal == "": 0 else: parseInt(defaultVal)
              )
            ),
            newNimNode(nnkElse).add(newCall("parseInt", foundGroup))
          )
        )
      of "float":
        letSection[0].add(newNimNode(nnkIfStmt).add(
            newNimNode(nnkElifBranch).add(
              conditionOptional,
              newLit(
                if defaultVal == "": 0.0 else: parseFloat(defaultVal)
              )
            ),
            newNimNode(nnkElifBranch).add(
              conditionSecondOptional,
              newLit(
                if defaultVal == "": 0.0 else: parseFloat(defaultVal)
              )
            ),
            newNimNode(nnkElse).add(newCall("parseFloat", foundGroup))
          )
        )
      of "string", "word":
        letSection[0].add(newNimNode(nnkIfStmt).add(
            newNimNode(nnkElifBranch).add(
              conditionOptional,
              newLit(
                if defaultVal == "": "" else: defaultVal
              )
            ),
            newNimNode(nnkElifBranch).add(
              conditionSecondOptional,
              newLit(
                if defaultVal == "": "" else: defaultVal
              )
            ),
            newNimNode(nnkElse).add(foundGroup)
          )
        )
      else:
        # regex
        letSection[0].add(foundGroup)
    else:
      case argTypeStr:
      of "bool":
        letSection[0].add(newCall("parseBool", foundGroup))
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
  
  let body =
    when defined(httpx):
      newCall("get", newDotExpr(ident("req"), ident("body")))
    else:
      newDotExpr(ident("req"), ident("body"))

  for i in foundModels:
    name = i.group(1, path)[0]
    isMutable = i.group(2, path).len != 0
    let modelKey = $name
    elifBranch[1].insert(
      0,
      newNimNode(if isMutable: nnkVarSection else: nnkLetSection).add(
        newIdentDefs(
          ident(i.group(0, path)[0]),
          newEmptyNode(),
          newNimNode(nnkTryStmt).add(
            newCall("jsonTo" & modelKey, newCall("parseJson", body))
          ).add(newNimNode(nnkExceptBranch).add(
            ident("JsonParsingError"),
            newStmtList(
              when defined(debug):
                newCall("echo", newCall("fmt", newStrLitNode("json parse error: {getCurrentExceptionMsg()}")))
              else:
                discardStmt,
              newCall("jsonTo" & modelKey, newCall("newJObject"))
            )
          ))
        )
      )
    )
    hasChildren = true
  
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
