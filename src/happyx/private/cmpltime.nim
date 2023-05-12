import
  strformat,
  strutils,
  macros,
  regex


proc exportRouteArgs*(urlPath, routePath, body: NimNode): NimNode {.compileTime.} =
  ## Finds and exports route arguments
  let
    elifBranch = newNimNode(nnkElifBranch)
    dollarToCurve = re"\$([^:\/\{\}]+)(:\w+)?(=[^\/\{\}]+)?"
    defaultWithoutQuestion = re"\{([^:\/\{\}\?]+)(:\w+)?(=[^\/\{\}]+)\}"
  var
    path = $routePath
    routePathStr = $routePath
    hasChildren = false
  # adaptive $params and repair default params
  path = path.replace(dollarToCurve, "{$1$2$3}")
  routePathStr = routePathStr.replace(dollarToCurve, "{$1$2$3}")
  path = path.replace(defaultWithoutQuestion, "{$1?$2$3}")
  routePathStr = routePathStr.replace(defaultWithoutQuestion, "{$1?$2$3}")
  # boolean param
  routePathStr = routePathStr.replace(re"\{[a-zA-Z][a-zA-Z0-9_]*(\??):bool(=\S+?)?\}", "(n|y|no|yes|true|false|1|0|on|off)$1")
  # integer param
  routePathStr = routePathStr.replace(re"\{[a-zA-Z][a-zA-Z0-9_]*(\??):int(=\S+?)?\}", "(\\d+)$1")
  # float param
  routePathStr = routePathStr.replace(re"\{[a-zA-Z][a-zA-Z0-9_]*(\??):float(=\S+?)?\}", "(\\d+\\.\\d+|\\d+)$1")
  # word param
  routePathStr = routePathStr.replace(re"\{[a-zA-Z][a-zA-Z0-9_]*(\??):word(=\S+?)?\}", "(\\w+)$1")
  # string param
  routePathStr = routePathStr.replace(re"\{[a-zA-Z][a-zA-Z0-9_]*(\??):string(=\S+?)?\}", "([^/]+)$1")
  routePathStr = routePathStr.replace(re"\{[a-zA-Z][a-zA-Z0-9_]*(\??)(=\S+?)?\}", "([^/]+)$1")
  # path param
  routePathStr = routePathStr.replace(re"\{[a-zA-Z][a-zA-Z0-9_]*:path\}", "([\\S]+)")
  # regex param
  routePathStr = routePathStr.replace(re"\{[a-zA-Z][a-zA-Z0-9_]*:/([\s\S]+?)/\}", "($1)")
  # repair param
  # routePathStr = routePathStr.replace(re"(\([^\(\)]+?\))(?!\?)", "$1?")
  let
    regExp = newCall("re", newStrLitNode("^" & routePathStr & "$"))
    found = path.findAll(
      re"\{([a-zA-Z][a-zA-Z0-9_]*\??)(:(bool|int|float|string|path|word|/[\s\S]+?/))?(=(\S+?))?\}"
    )
  echo treeRepr regExp
  elifBranch.add(newCall("contains", urlPath, regExp), body)
  var
    idx = 0
    name = ""
    isOptional = false
    defaultVal = ""
  for i in found:
    # clean
    name = i.group(0, path)[0]
    isOptional = false
    defaultVal =
      if i.group(4, path).len == 0:
        ""
      else:
        i.group(4, path)[0]
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
      letSection = newNimNode(nnkLetSection).add(
        newNimNode(nnkIdentDefs).add(ident(name), newEmptyNode())
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
    if isOptional:
      case argTypeStr:
      of "bool":
        letSection[0].add(newNimNode(nnkIfStmt).add(
            newNimNode(nnkElifBranch).add(
              newCall(
                "<",
                newCall("len", newCall(
                  "group",
                  newNimNode(nnkBracketExpr).add(ident("founded_regexp_matches"), newIntLitNode(0)),
                  newIntLitNode(idx),  # group index,
                  urlPath
                )),
                newIntLitNode(1)
              ),
              newLit(
                if defaultVal == "": false else: parseBool(defaultVal)
              )
            ),
            newNimNode(nnkElifBranch).add(
              newCall("==", newCall("len", foundGroup), newIntLitNode(0)),
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
              newCall(
                "<",
                newCall("len", newCall(
                  "group",
                  newNimNode(nnkBracketExpr).add(ident("founded_regexp_matches"), newIntLitNode(0)),
                  newIntLitNode(idx),  # group index,
                  urlPath
                )),
                newIntLitNode(1)
              ),
              newLit(
                if defaultVal == "": 0 else: parseInt(defaultVal)
              )
            ),
            newNimNode(nnkElifBranch).add(
              newCall("==", newCall("len", foundGroup), newIntLitNode(0)),
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
              newCall(
                "<",
                newCall("len", newCall(
                  "group",
                  newNimNode(nnkBracketExpr).add(ident("founded_regexp_matches"), newIntLitNode(0)),
                  newIntLitNode(idx),  # group index,
                  urlPath
                )),
                newIntLitNode(1)
              ),
              newLit(
                if defaultVal == "": 0.0 else: parseFloat(defaultVal)
              )
            ),
            newNimNode(nnkElifBranch).add(
              newCall("==", newCall("len", foundGroup), newIntLitNode(0)),
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
              newCall(
                "<",
                newCall("len", newCall(
                  "group",
                  newNimNode(nnkBracketExpr).add(ident("founded_regexp_matches"), newIntLitNode(0)),
                  newIntLitNode(idx),  # group index,
                  urlPath
                )),
                newIntLitNode(1)
              ),
              newLit(
                if defaultVal == "": "" else: defaultVal
              )
            ),
            newNimNode(nnkElifBranch).add(
              newCall("==", newCall("len", foundGroup), newIntLitNode(0)),
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