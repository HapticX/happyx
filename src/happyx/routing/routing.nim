## Provides powerful routing ✨
## 

import
  # stdlib
  std/strformat,
  std/strutils,
  std/strtabs,
  std/unicode,
  std/macros,
  std/macrocache,
  std/enumutils,
  std/json,
  # happyx
  ../core/[exceptions, constants],
  ../private/macro_utils,
  ../private/scanutils


export
  scanutils,
  enumutils


when exportPython or defined(docgen):
  import
    nimpy,
    nimpy/py_types,
    ../bindings/python_types
elif defined(napibuild):
  import
    denim,
    ../bindings/node_types
elif exportJvm:
  import
    jnim,
    jnim/private/[jni_wrapper],
    jnim/java/[lang, util],
    ../bindings/java_types


const
  declaredPathParams = CacheTable"HappyXDeclaredPathParams"
  onException* = CacheTable"HappyXOnException"


static:
  onException["e"] = newStmtList()


type
  PathParamObj* = object
    name*: string
    paramType*: string
    defaultValue*: string
    optional*: bool
  RequestModelObj* = object
    name*: string
    typeName*: string
    target*: string  ## JSON/XML/FormData/X-www-formurlencoded
  RouteDataObj* = object
    pathParams*: seq[PathParamObj]
    requestModels*: seq[RequestModelObj]
    purePath*: string
    path*: string


when exportJvm:
  import tables


proc newPathParamObj*(name, paramType, defaultValue: string, optional: bool): PathParamObj =
  PathParamObj(name: name, paramType: paramType, defaultValue: defaultValue, optional: optional)

proc newRequestModelObj*(name, typeName, target: string): RequestModelObj =
  RequestModelObj(name: name, typeName: typeName, target: target)


proc boolean*(input: string, boolVal: var bool, start: int, opt: bool = false): int =
  let inp = input[start..^1]
  if inp.startsWith("off"):
    boolVal = false
    return 3
  elif inp.startsWith("false"):
    boolVal = false
    return 5
  elif inp.startsWith("no"):
    boolVal = false
    return 2
  elif inp.startsWith("on"):
    boolVal = true
    return 2
  elif inp.startsWith("true"):
    boolVal = true
    return 4
  elif inp.startsWith("yes"):
    boolVal = true
    return 3
  if opt:
    return 0
  return -1


proc word*(input: string, strVal: var string, start: int, opt: bool = false): int =
  result = 0
  if input.len <= start or not input.runeAt(start).isAlpha:
    if opt:
      return 0
    return -1
  var res = ""
  for s in input[start..^1].runes:
    if s.isAlpha:
      res &= $s
      inc result
    else:
      break
  strVal = res


proc str*(input: string, strVal: var string, start: int, opt: bool = false): int =
  result = 0
  if input.len <= start or input[start] == '/':
    if opt:
      return 0
    return -1
  var res = ""
  for c in input[start..^1]:
    if c != '/':
      res &= c
      inc result
    else:
      break
  strVal = res


proc enumerate*[T: enum](input: string, e: var T, start: int, opt: bool = false): int =
  let inp = input[start..^1]
  for i in T:
    if inp.startsWith(i.symbolName):
      e = i
      return i.symbolName.len
    elif inp.startsWith($i):
      e = i
      return len($i)
  if opt:
    return 0
  return -1


proc integer*(input: string, intVal: var int, start: int, opt: bool = false): int =
  result = 0
  if input.len <= start or not input[start].isDigit:
    if opt:
      return 0
    return -1
  var res = ""
  for c in input[start..^1]:
    if c.isDigit:
      res &= c
      inc result
    else:
      break
  intVal = res.parseInt


proc realnum*(input: string, floatVal: var float, start: int, opt: bool = false): int =
  result = 0
  if input.len <= start or not input[start].isDigit:
    if opt:
      return 0
    return -1
  var res = ""
  for c in input[start..^1]:
    if c.isDigit or c == '.':
      res &= c
      inc result
    else:
      break
  floatVal = res.parseFloat


proc default*(input: string, strVal: var string, start: int): int =
  result = 0
  var i = 0
  while start+i < input.len:
    if input[start+i] == '}':
      break
    strVal &= input[start+i]
    inc result
    inc i


proc kind*(input: string, strVal: var string, start: int): int =
  result = 0
  let inp = input[start..^1]
  if inp.startsWith("int"):
    strVal = "int"
    inc result, 3
  elif inp.startsWith("bool"):
    strVal = "bool"
    inc result, 4
  elif inp.startsWith("path"):
    strVal = "path"
    inc result, 4
  elif inp.startsWith("word"):
    strVal = "word"
    inc result, 4
  elif inp.startsWith("float"):
    strVal = "float"
    inc result, 5
  elif inp.startsWith("string"):
    strVal = "string"
    inc result, 6
  elif inp.startsWith("enum"):
    strVal = "enum::"
    var opened = false
    for i in inp[4..^1]:
      if i == '(':
        inc result
        opened = true
      elif i == ')':
        inc result
        break
      elif opened:
        strVal &= i
        inc result
    inc result, 4

proc path*(input: string, strVal: var string, start: int): int =
  strVal = input[start..^1]
  strVal.len


proc kind2scanable(kind: string, opt: bool): string =
  if opt:
    case kind
    of "string":
      "${str(true)}"
    of "int":
      "${integer(true)}"
    of "float":
      "${realnum(true)}"
    of "bool":
      "${boolean(true)}"
    of "word":
      "${word(true)}"
    of "path":
      "${path}"
    else:
      if kind.startsWith("enum"):
        "${enumerate}"
      else:
        ""
  else:
    case kind
    of "string":
      "${str}"
    of "int":
      "$i"
    of "float":
      "$f"
    of "bool":
      "${boolean}"
    of "word":
      "${word}"
    of "path":
      "${path}"
    else:
      if kind.startsWith("enum"):
        "${enumerate}"
      else:
        ""


proc kind2tp(kind: string): string =
  case kind
  of "string", "word", "path":
    "string"
  of "int":
    "int"
  of "float":
    "float"
  of "bool":
    "bool"
  else:
    if kind.startsWith("enum"):
      kind.split("::", 1)[1]
    else:
      ""


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


proc findParams(route: string, purePath: var string): seq[tuple[name, kind: string, opt: bool, def: string]] =
  result = @[]
  var i = 0
  while i < route.len:
    let part = route[i..^1]
    var
      name: string
      kind: string = "string"
      def: string
    # {arg?:type=default}
    if part.scanf("{$w?:${kind}=${default}}", name, kind, def):
      result.add((name: name, kind: kind, opt: true, def: def))
      purePath &= kind2scanable(kind, true)
      inc i, 5 + name.len + kind.len + def.len
    # $arg?:type=default
    elif part.scanf("$$$w?:${kind}=${default}", name, kind, def):
      result.add((name: name, kind: kind, opt: true, def: def))
      purePath &= kind2scanable(kind, true)
      inc i, 4 + name.len + kind.len + def.len
    # {arg:type=default}
    elif part.scanf("{$w:${kind}=${default}}", name, kind, def):
      result.add((name: name, kind: kind, opt: true, def: def))
      purePath &= kind2scanable(kind, true)
      inc i, 4 + name.len + kind.len + def.len
    # $arg:type=default
    elif part.scanf("$$$w:${kind}=${default}", name, kind, def):
      result.add((name: name, kind: kind, opt: true, def: def))
      purePath &= kind2scanable(kind, true)
      inc i, 3 + name.len + kind.len + def.len
    # {arg=default}
    elif part.scanf("{$w=${default}}", name, def):
      result.add((name: name, kind: kind, opt: true, def: def))
      purePath &= kind2scanable(kind, true)
      inc i, 3 + name.len + def.len
    # $arg=default
    elif part.scanf("$$$w=${default}", name, def):
      result.add((name: name, kind: kind, opt: true, def: def))
      purePath &= kind2scanable(kind, true)
      inc i, 2 + name.len + def.len
    # {arg:type}
    elif part.scanf("{$w:${kind}}", name, kind):
      result.add((name: name, kind: kind, opt: false, def: def))
      purePath &= kind2scanable(kind, false)
      inc i, 3 + name.len + kind.len
    # $arg:type
    elif part.scanf("$$$w:${kind}", name, kind):
      result.add((name: name, kind: kind, opt: false, def: def))
      purePath &= kind2scanable(kind, false)
      inc i, 2 + name.len + kind.len
    # {arg?=default}
    elif part.scanf("{$w?=${default}}", name, def):
      result.add((name: name, kind: kind, opt: true, def: def))
      purePath &= kind2scanable(kind, true)
      inc i, 4 + name.len + def.len
    # $arg?=default
    elif part.scanf("$$$w?=${default}", name, def):
      result.add((name: name, kind: kind, opt: true, def: def))
      purePath &= kind2scanable(kind, true)
      inc i, 3 + name.len + def.len
    # {arg?:type}
    elif part.scanf("{$w?:${kind}}", name, kind):
      result.add((name: name, kind: kind, opt: true, def: def))
      purePath &= kind2scanable(kind, true)
      inc i, 4 + name.len + kind.len
    # $arg?:type
    elif part.scanf("$$$w?:${kind}", name, kind):
      result.add((name: name, kind: kind, opt: true, def: def))
      purePath &= kind2scanable(kind, true)
      inc i, 3 + name.len + kind.len
    # {arg?}
    elif part.scanf("{$w?}", name):
      result.add((name: name, kind: kind, opt: true, def: def))
      purePath &= kind2scanable(kind, true)
      inc i, 3 + name.len
    # $arg?
    elif part.scanf("$$$w?", name):
      result.add((name: name, kind: kind, opt: true, def: def))
      purePath &= kind2scanable(kind, true)
      inc i, 2 + name.len
    # {arg}
    elif part.scanf("{$w}", name):
      result.add((name: name, kind: kind, opt: true, def: def))
      purePath &= kind2scanable(kind, true)
      inc i, 2 + name.len
    # $arg
    elif part.scanf("$$$w", name):
      result.add((name: name, kind: kind, opt: true, def: def))
      purePath &= kind2scanable(kind, true)
      inc i, 1 + name.len
    # [arg:ModelName]
    elif part.scanf("[$w:$w]", name, kind):
      inc i, 3 + name.len + kind.len
    # [arg:ModelName:json]
    elif part.scanf("[$w:$w:$w]", name, kind, def):
      inc i, 4 + name.len + kind.len + def.len
    else:
      purePath &= route[i]
      inc i
    # echo part, " -> ", name, ": ", kind, " = ", def
  # echo result


proc findModels(route: string): seq[tuple[name, kind, mode: string]] =
  result = @[]
  var i = 0
  while i < route.len:
    let part = route[i..^1]
    var
      name: string
      kind: string
      mode: string = "JSON"
    # [arg:ModelName]
    if part.scanf("[$w:$w]", name, kind):
      result.add((name: name, kind: kind, mode: mode))
      inc i, 3 + name.len + kind.len
    # [arg:ModelName:json]
    elif part.scanf("[$w:$w:$w]", name, kind, mode):
      result.add((name: name, kind: kind, mode: mode))
      inc i, 4 + name.len + kind.len + mode.len
    else:
      inc i


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
    when enableHttpBeast or enableHttpx:
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


when exportPython or defined(docgen) or defined(napibuild) or exportJvm:
  proc parseBoolOrJString*(str: string): JsonNode =
    try:
      return newJBool(parseBool(str))
    except system.Exception:
      return newJString(str)
  proc parseIntOrJString*(str: string): JsonNode =
    try:
      return newJInt(parseInt(str))
    except system.Exception:
      return newJString(str)
  proc parseFloatOrJString*(str: string): JsonNode =
    try:
      return newJFloat(parseFloat(str))
    except system.Exception:
      return newJString(str)
  

  proc processJson(self: var JsonNode, fields: RequestModelData) =
    for field in fields.fields:
      if field.val in requestModelsHidden:
        var obj = newJObject()
        obj.processJson(requestModelsHidden[field.key])
        self[field.key] = obj
      else:
        case field.val
        of "str", "string", "unicode":
          if self[field.key].kind != JString:
            self[field.key] = newJString($self[field.key])
        of "int":
          if self[field.key].kind != JInt:
            self[field.key] = parseIntOrJString($self[field.key])
        of "float":
          if self[field.key].kind != JFloat:
            self[field.key] = parseFloatOrJString($self[field.key])
        of "bool":
          if self[field.key].kind != JBool:
            self[field.key] = parseBoolOrJString($self[field.key])


  proc convertJson*(self: RequestModelData, body: string): JsonNode =
    ## Converts Request JSON to Python dict
    var data: JsonNode
    try:
      data = parseJson(body)
      data.processJson(self)
      return data
    except JsonParsingError:
      data = newJObject()


  template condition(condition1, condition2, foundGroup, defaultValue, jsonFunc, parseFunc, res, name, val: untyped): untyped =
    when parseFunc is void:
      if `condition1` or `condition2`:
        if `defaultValue` == "":
          `res`[`name`] = `jsonFunc`(`val`)
        else:
          `res`[`name`] = `jsonFunc`(`defaultValue`)
      else:
        `res`[`name`] = `jsonFunc`(`foundGroup`)
    else:
      if `condition1` or `condition2`:
        if `defaultValue` == "":
          `res`[`name`] = `jsonFunc`(`val`)
        else:
          `res`[`name`] = `parseFunc`(`defaultValue`)
      else:
        `res`[`name`] = `parseFunc`(`foundGroup`)
    
  when exportPython:
    type RouteObject* = PyObject
  elif exportJvm:
    type RouteObject* = PathParam
  elif defined(napibuild):
    type RouteObject* = napi_value
  else:
    type RouteObject* = JsonNode

  proc getRouteParams*(routeData: RouteDataObj, found_regexp_matches: seq[RegexMatch2],
                       urlPath: string = "", handlerParams: seq[HandlerParam] = @[], body: string = "",
                       force: bool = false): RouteObject =
    ## Finds and exports route arguments
    when exportPython:
      var res = pyDict()
    elif exportJvm:
      var res = PathParam(name: "", kind: ppkObj, objVal: newTable[string, PathParam]())
    else:
      var res = newJObject()
    var idx = 0
    for i in routeData.pathParams:
      if i.name notin handlerParams and not force:
        continue
      let
        group = found_regexp_matches[0].group(idx)
        foundGroup = urlPath[group]
        conditionOptional = group.len < 1
        conditionSecondOptional = foundGroup.len == 0
        paramType =
          if not force:
            handlerParams[i.name]
          else:
            i.paramType
        defaultValue = i.defaultValue
        name = i.name

      if i.optional:
        if i.paramType == "string":
          # Detect type from annotations
          case paramType
          of "bool":
            res[i.name] = parseBoolOrJString(foundGroup)
          of "int":
            res[i.name] = parseIntOrJString(foundGroup)
          of "float":
            res[i.name] = parseFloatOrJString(foundGroup)
          else:
            res[i.name] = newJString(foundGroup)
        else:
          # Detect type from route
          case i.paramType:
          of "bool":
            condition(conditionOptional, conditionSecondOptional, foundGroup, defaultValue, newJBool, parseBoolOrJString, res, name, false)
          of "int":
            condition(conditionOptional, conditionSecondOptional, foundGroup, defaultValue, newJInt, parseIntOrJString, res, name, 0)
          of "float":
            condition(conditionOptional, conditionSecondOptional, foundGroup, defaultValue, newJFloat, parseFloatOrJString, res, name, 0.0)
          of "word":
            condition(conditionOptional, conditionSecondOptional, foundGroup, defaultValue, newJString, void, res, name, "")
          else:
            res[i.name] = newJString(foundGroup)
      elif i.paramType == "string":
        # Detect type from annotations
        case paramType
        of "bool":
          res[i.name] = parseBoolOrJString(foundGroup)
        of "int":
          res[i.name] = parseIntOrJString(foundGroup)
        of "float":
          res[i.name] = parseFloatOrJString(foundGroup)
        else:
          res[i.name] = newJString(foundGroup)
      else:
        # Detect from route
        case i.paramType:
        of "bool":
          res[i.name] = parseBoolOrJString(foundGroup)
        of "int":
          res[i.name] = parseIntOrJString(foundGroup)
        of "float":
          res[i.name] = parseFloatOrJString(foundGroup)
        of "path", "string", "word":
          res[i.name] = newJString(foundGroup)
        else:
          res[i.name] = newJString(foundGroup)
      inc idx

    for i in routeData.requestModels:
      let
        paramType = handlerParams[i.name]
      var
        modelData: RequestModelData
        hasModelData = false
      if i.typeName != "":
        if i.typeName in requestModelsHidden:
          modelData = requestModelsHidden[i.typeName]
          hasModelData = true
      elif paramType in requestModelsHidden:
          modelData = requestModelsHidden[paramType]
          hasModelData = true
      if hasModelData:
        case i.target.toLower()
        of "json":
          res[i.name] = convertJson(modelData, body)
    when defined(napibuild):
      return res.toJsObj()
    else:
      return res


proc pathParamsBoilerplate(node: NimNode, kind, regexVal: var string) =
  if node.kind == nnkIdent:
    kind = $node
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
  ##      # means that `arg` of type `int` is optional param with default value `5`
  ##      arg? int = 5
  ##      # means that `arg1` of type `string` is optional param with default value `"Hello"`
  ##      arg1 = "Hello"
  ##      # means that `arg2` of type `float` is param
  ##      arg2 float
  ##      # means that `arg3` of type `int` is optional param with default value `10`
  ##      arg3:
  ##        type int
  ##        optional
  ##        default = 10
  ## 
  for statement in body:
    var
      name = ""
      kind = "string"
      regexVal = ""
      isOptional = false
      defaultVal = ""
    
    # Just ident
    if statement.kind == nnkIdent:
      name = $statement
    
    # Assignment
    # argument? type = val
    elif statement.kind == nnkAsgn:
      if statement[0].kind == nnkInfix and $statement[0][0] == "?":
        # name
        name = $statement[0][1]
        # type
        if statement[0].len == 3:
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
    
    # infix
    # argument? type[m]
    elif statement.kind == nnkInfix and $statement[0] == "?":
      # name
      name = $statement[1]
      isOptional = true
      # type
      if statement.len == 3:
        pathParamsBoilerplate(statement[2], kind, regexVal)
    
    # command
    elif statement.kind in [nnkCall, nnkCommand]:
      name = $statement[0]
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
            else:
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
      res &= ":" & kind
      if defaultVal.len > 0:
        res &= "=" & defaultVal
      if declaredPathParams.hasKey(name):
        throwDefect(
          HpxPathParamDefect,
          fmt"param {name} is declared! ",
          lineInfoObj(statement)
        )
      declaredPathParams[name] = newLit(res & "}")
