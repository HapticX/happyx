## Provides powerful routing ✨
## 

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
  ../core/[exceptions, constants],
  ../private/[macro_utils]


var
  declaredPathParams {. compileTime .} = newStringTable()


proc exportRouteArgs*(urlPath, routePath, body: NimNode): NimNode {.compileTime.} =
  ## Finds and exports route arguments
  ## 
  ## [Read more about it](/happyx/happyx/routing.html)
  let
    elifBranch = newNimNode(nnkElifBranch)
    dollarToCurve = re"\$([^:\/\{\}]+)(:enum\(\w+\)|:\w+)?(\[m\])?(=[^\/\{\}]+)?(m)?"
    defaultWithoutQuestion = re"\{([^:\/\{\}\?]+)(:enum\(\w+\)|:\w+)?(\[m\])?(=[^\/\{\}]+)\}"
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
        HpxPathParamDefect,
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
  # string enum
  routePathStr = routePathStr.replace(re"\{[a-zA-Z][a-zA-Z0-9_]*(\??):enum\((\w+)\)(\[m\])?(=\S+?)?\}", "(\\w+)$1")
  # string param
  routePathStr = routePathStr.replace(re"\{[a-zA-Z][a-zA-Z0-9_]*(\??):string(\[m\])?(=\S+?)?\}", "([^/]+)$1")
  routePathStr = routePathStr.replace(re"\{[a-zA-Z][a-zA-Z0-9_]*(\??)(\[m\])?(=\S+?)?\}", "([^/]+)$1")
  # path param
  routePathStr = routePathStr.replace(re"\{[a-zA-Z][a-zA-Z0-9_]*:path(\[m\])?\}", "([\\S]+)")
  # regex param
  routePathStr = routePathStr.replace(re"\{[a-zA-Z][a-zA-Z0-9_]*:/([\s\S]+?)/(\[m\])?\}", "($1)")
  # Remove models
  routePathStr = routePathStr.replace(re"\[[a-zA-Z][a-zA-Z0-9_]*:[a-zA-Z][a-zA-Z0-9_]*(\[m\])?(:[a-zA-Z\\-]+)?\]", "")
  let
    regExp = newCall("re", newStrLitNode("^" & routePathStr & "$"))
    found = path.findAll(
      re"\{([a-zA-Z][a-zA-Z0-9_]*\??)(:(bool|int|float|string|path|word|/[\s\S]+?/|enum\(\w+\)))?(\[m\])?(=(\S+?))?\}"
    )
    foundModels = path.findAll(
      re"\[([a-zA-Z][a-zA-Z0-9_]*):([a-zA-Z][a-zA-Z0-9_]*)(\[m\])?(:[a-zA-Z\\-]+)?\]"
    )
  elifBranch.add(newCall("contains", urlPath, regExp), body)
  var
    idx = 0
    name = ""
    isOptional = false
    defaultVal = ""
    isMutable = false
  let paramsCount = found.len
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
        newNimNode(nnkBracketExpr).add(
          if paramsCount > 1:
            ident"founded_regexp_matches"
          else:
            newCall("findAll", urlPath, regExp),
          newIntLitNode(0)
        ),
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
        # string Enum
        if ($argTypeStr).startsWith("enum"):
          let enumName = ($argTypeStr)[5..^2]
          letSection[0].add(newNimNode(nnkIfStmt).add(
            newNimNode(nnkElifBranch).add(
              conditionOptional,
              if defaultVal == "":
                newCall("default", ident(enumName))
              else:
                newCall(newNimNode(nnkBracketExpr).add(ident"parseEnum", ident(enumName)), newStrLitNode(defaultVal), newCall("default", ident(enumName)))
            ),
            newNimNode(nnkElifBranch).add(
              conditionSecondOptional,
              if defaultVal == "":
                newCall("default", ident(enumName))
              else:
                newCall(newNimNode(nnkBracketExpr).add(ident"parseEnum", ident(enumName)), newStrLitNode(defaultVal), newCall("default", ident(enumName)))
            ),
            newNimNode(nnkElse).add(
              newCall(newNimNode(nnkBracketExpr).add(ident"parseEnum", ident(enumName)), foundGroup, newCall("default", ident(enumName)))
            )
          ))
        # regex
        else:
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
        # string Enum
        if ($argTypeStr).startsWith("enum"):
          let enumName = ($argTypeStr)[5..^2]
          letSection[0].add(newCall(newNimNode(nnkBracketExpr).add(ident"parseEnum", ident(enumName)), foundGroup, newCall("default", ident(enumName))))
        # regex
        else:
          letSection[0].add(foundGroup)
    elifBranch[1].insert(0, letSection)
    hasChildren = true
    inc idx
  
  let body =
    when enableHttpBeast or enableHttpx:
      newCall("get", newDotExpr(ident"req", ident"body"))
    else:
      newDotExpr(ident"req", ident"body")

  # Models
  for i in foundModels:
    let
      modelType = i.group(1, path)[0]
      modelKey = $modelType
      modelName = i.group(0, path)[0]
      modelTarget =
        if i.group(3, path).len != 0:
          i.group(3, path)[0][1..^1]
        else:
          "JSON"
    isMutable = i.group(2, path).len != 0
    elifBranch[1].insert(
      0,
      newNimNode(if isMutable: nnkVarSection else: nnkLetSection).add(
        newIdentDefs(
          ident(modelName),
          newEmptyNode(),
          case modelTarget.toLower():
          of "json":
            newNimNode(nnkTryStmt).add(
              newCall("jsonTo" & modelKey, newCall("parseJson", body))
            ).add(newNimNode(nnkExceptBranch).add(
              ident"JsonParsingError",
              newStmtList(
                when defined(debug):
                  newCall("echo", newCall("fmt", newStrLitNode("json parse error: {getCurrentExceptionMsg()}")))
                else:
                  newEmptyNode(),
                newCall("jsonTo" & modelKey, newCall("newJObject"))
              )
            ))
          of "urlencoded", "x-www-form-urlencoded", "xwwwformurlencoded":
            newCall("xWwwUrlencodedTo" & modelKey, body)
          of "form-data", "formdata":
            newCall("formDataTo" & modelKey, body)
          of "xml":
            newCall("xmlBodyTo" & modelKey, body)
          else:
            newCall("jsonTo" & modelKey, newCall("newJObject"))
        )
      )
    )
    hasChildren = true
  
  if hasChildren:
    if paramsCount > 1:
      elifBranch[1].insert(
        0, newNimNode(nnkLetSection).add(
          newIdentDefs(
            ident"founded_regexp_matches", newEmptyNode(), newCall("findAll", urlPath, regExp)
          )
        )
      )
    return elifBranch
  return newEmptyNode()


proc pathParamsBoilerplate(node: NimNode, kind, regexVal: var string) =
  if node.kind == nnkIdent:
    kind = $node
  # regex type
  elif node.kind == nnkCallStrLit and $node[0] == "re":
    kind = "regex"
    regexVal = $node[1]
  elif node.kind == nnkExprEqExpr:
    kind = $(node[0].toStrLit)
  else:
    let current = $node.toStrLit
    throwDefect(
      HpxPathParamDefect,
      "Invalid path param type: " & current,
      lineInfoObj(node)
    )


macro pathParams*(body: untyped): untyped =
  ## `pathParams` provides path params assignment ✨.
  ## 
  ## Simple usage:
  ## 
  ## .. code-block:: nim
  ##    pathParams:
  ##      # means that `arg` of type `int` is optional mutable param with default value `5`
  ##      arg? int[m] = 5
  ##      # means that `arg1` of type `string` is optional mutable param with default value `"Hello"`
  ##      arg1[m] = "Hello"
  ##      # means that `arg2` of type `string` is immutable regex param
  ##      arg2 re"\d+u"
  ##      # means that `arg3` of type `float` is mutable param
  ##      arg3 float[m]
  ##      # means that `arg4` of type `int` is optional mutable param with default value `10`
  ##      arg4:
  ##        type int
  ##        mutable
  ##        optional
  ##        default = 10
  ## 
  for statement in body:
    var
      name = ""
      kind = "string"
      regexVal = ""
      isMutable = false
      isOptional = false
      defaultVal = ""
    
    # Just ident
    if statement.kind == nnkIdent:
      name = $statement
    
    # Assignment
    # argument? type[m] = val
    elif statement.kind == nnkAsgn:
      if statement[0].kind == nnkInfix and $statement[0][0] == "?":
        # name
        name = $statement[0][1]
        # type
        if statement[0].len == 3:
          # type[m]
          if statement[0][2].kind == nnkBracketExpr and $statement[0][2][1] == "m":
            isMutable = true
            pathParamsBoilerplate(statement[0][2][0], kind, regexVal)
          # type
          else:
            pathParamsBoilerplate(statement[0][2], kind, regexVal)
            kind = $statement[0][2]
        # default val
        if statement[1].kind in AtomicNodes:
          defaultVal = $statement[1].toStrLit
          isOptional = true
        else:
          let current = $statement[1].toStrLit
          throwDefect(
            HpxPathParamDefect,
            "Invalid path param default value (should be atomic const types)" & current,
            lineInfoObj(statement[1])
          )
      # arg[m]
      elif statement[0].kind == nnkBracketExpr and $statement[0][1] == "m":
        isMutable = true
        name = $statement[0][0]
        # default val
        if statement[1].kind in AtomicNodes:
          defaultVal = $statement[1].toStrLit
          isOptional = true
        else:
          let current = $statement[1].toStrLit
          throwDefect(
            HpxPathParamDefect,
            "Invalid path param default value (should be atomic const types)" & current,
            lineInfoObj(statement[1])
          )
    
    # infix
    # argument? type[m]
    elif statement.kind == nnkInfix and $statement[0] == "?":
      # name
      name = $statement[1]
      isOptional = true
      # type
      if statement.len == 3:
        # type[m]
        if statement[2].kind == nnkBracketExpr and $statement[2][1] == "m":
          pathParamsBoilerplate(statement[2][0], kind, regexVal)
        # type
        else:
          pathParamsBoilerplate(statement[2], kind, regexVal)
    
    # command
    elif statement.kind in [nnkCall, nnkCommand]:
      name = $statement[0]
      # type[m]
      if statement[1].kind == nnkBracketExpr and $statement[1][1] == "m":
        isMutable = true
        pathParamsBoilerplate(statement[1][0], kind, regexVal)
      # type
      else:
        pathParamsBoilerplate(statement[1], kind, regexVal)
      # stmt list
      if statement[^1].kind == nnkStmtList:
        for child in statement[^1].children:
          case child.kind
          # optional, mutable etc.
          of nnkIdent:
            let childStr = $child
            if childStr == "optional":
              isOptional = true
            elif childStr == "mutable":
              isMutable = true
            else:
              let current = childStr
              throwDefect(
                HpxPathParamDefect,
                "Invalid flag for path param: " & childStr,
                lineInfoObj(child)
              )
          of nnkTypeSection:
            # param type
            if child[0].kind == nnkTypeDef and child[0][0].kind == nnkIdent:
              kind = $child[0][0]
          of nnkAsgn:
            let childStr = $child[0]
            # default val
            if childStr == "default":
              if child[1].kind in AtomicNodes:
                defaultVal = $child[1].toStrLit
                isOptional = true
          else:
            let
              current = $child.toStrLit
              allStatement = ($statement[^1].toStrLit).replace(current, "> " & current)
            throwDefect(
              HpxPathParamDefect,
              "invalid path param assignment:" & allStatement,
              lineInfoObj(child)
            )
    
    if name.len > 0:
      var res = "{" & name
      if isOptional:
        res &= "?"
      if kind != "regex":
        res &= ":" & kind
      else:
        res &= ":/" & regexVal & "/"
      if isMutable:
        res &= "[m]"
      if defaultVal.len > 0:
        res &= "=" & defaultVal
      if declaredPathParams.hasKey(name):
        throwDefect(
          HpxPathParamDefect,
          fmt"param {name} is declared! ",
          lineInfoObj(statement)
        )
      declaredPathParams[name] = res & "}"
