import
  macros,
  regex


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
  elifBranch.add(newCall("contains", urlPath, regExp), body)
  var idx = 0
  for i in found:
    let
      name = ident(i.group(0, path)[0])
      argTypeStr = i.group(1, path)[0]
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