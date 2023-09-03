## Provides powerful routing ✨
## 

import
  # stdlib
  strformat,
  strutils,
  strtabs,
  macros,
  tables,
  json,
  # deps
  regex,
  # happyx
  ../core/[exceptions, constants]


when exportPython or defined(docgen):
  import
    nimpy,
    nimpy/py_types,
    ../bindings/python_types


var
  declaredPathParams {. compileTime .} = newStringTable()


type
  PathParamObj* = object
    name*: string
    paramType*: string
    defaultValue*: string
    optional*: bool
    mutable*: bool
  RequestModelObj* = object
    name*: string
    typeName*: string
    target*: string  ## JSON/XML/FormData/X-www-formurlencoded
    mutable*: bool
  RouteDataObj* = object
    pathParams*: seq[PathParamObj]
    requestModels*: seq[RequestModelObj]
    purePath*: string
    path*: string

when not exportPython:
  type RouteParamType = object
    name: string
    pattern: string
    creator: NimNode


  var registeredRouteParamTypes {.compileTime.} = newTable[string, RouteParamType]()


  macro registerRouteParamType*(name, pattern: string, creator: untyped) =
    if re2"^[a-zA-Z][a-zA-Z0-9_]*$" notin $name:
      raise newException(
        ValueError,
        fmt"route param type name should be identifier (a-zA-Z0-0_), but got '{name}'"
      )
    registeredRouteParamTypes[$name] = RouteParamType(
      pattern: $pattern, name: $name, creator: creator
    )

elif exportPython:
  type RouteParamType = object
    name: string
    pattern: string
    creator: PyObject


  var registeredRouteParamTypes = newTable[string, RouteParamType]()

  proc registerRouteParamTypeAux*(name, pattern: string, creator: PyObject) =
    if re2"^[a-zA-Z][a-zA-Z0-9_]*$" notin name:
      raise newException(
        ValueError,
        fmt"route param type name should be identifier (a-zA-Z0-0_), but got '{name}'"
      )
    registeredRouteParamTypes[name] = RouteParamType(
      pattern: pattern, name: name, creator: creator
    )
  
  proc hasObjectWithName*(self: TableRef[string, RouteParamType], name: string): bool =
    {.gcsafe.}:
      for v in registeredRouteParamTypes.values():
        if $(v.creator.getAttr("__class__").getAttr("__name__")) == name or $(v.creator.getAttr("__name__")) == name:
          return true
      return false
  
  proc getObjectWithName*(self: TableRef[string, RouteParamType], name: string): RouteParamType =
    {.gcsafe.}:
      for v in registeredRouteParamTypes.values():
        if $(v.creator.getAttr("__class__").getAttr("__name__")) == name or $(v.creator.getAttr("__name__")) == name:
          return v


proc newPathParamObj*(name, paramType, defaultValue: string, optional, mutable: bool): PathParamObj =
  PathParamObj(name: name, paramType: paramType, defaultValue: defaultValue,
               optional: optional, mutable: mutable)

proc newRequestModelObj*(name, typeName, target: string, mutable: bool): RequestModelObj =
  RequestModelObj(name: name, typeName: typeName, target: target, mutable: mutable)


proc handleRoute*(route: string): RouteDataObj =
  ## Handles route and receive route data object.
  result = RouteDataObj(path: "", purePath: "", pathParams: @[], requestModels: @[])
  let
    dollarToCurve = re2"\$([^:\/\{\}]+)(:enum\(\w+\)|:\w+)?(\[m\])?(=[^\/\{\}]+)?(m)?"
    defaultWithoutQuestion = re2"\{([^:\/\{\}\?]+)(:enum\(\w+\)|:\w+)?(\[m\])?(=[^\/\{\}]+)\}"

  var path = route
  path = path.replace(dollarToCurve, "{$1$2$3$4}")
  path = path.replace(defaultWithoutQuestion, "{$1?$2$3$4}")
  result.path = path
  var routePathStr = path
  # boolean param
  routePathStr = routePathStr.replace(re2"\{[a-zA-Z][a-zA-Z0-9_]*(\??):bool(\[m\])?(=\S+?)?\}", "(n|y|no|yes|true|false|1|0|on|off)$1")
  # integer param
  routePathStr = routePathStr.replace(re2"\{[a-zA-Z][a-zA-Z0-9_]*(\??):int(\[m\])?(=\S+?)?\}", "(\\d+)$1")
  # float param
  routePathStr = routePathStr.replace(re2"\{[a-zA-Z][a-zA-Z0-9_]*(\??):float(\[m\])?(=\S+?)?\}", "(\\d+\\.\\d+|\\d+)$1")
  # word param
  routePathStr = routePathStr.replace(re2"\{[a-zA-Z][a-zA-Z0-9_]*(\??):word(\[m\])?(=\S+?)?\}", "(\\w+)$1")
  # string enum
  routePathStr = routePathStr.replace(re2"\{[a-zA-Z][a-zA-Z0-9_]*(\??):enum\((\w+)\)(\[m\])?(=\S+?)?\}", "(\\w+)$1")
  # string param
  routePathStr = routePathStr.replace(re2"\{[a-zA-Z][a-zA-Z0-9_]*(\??):string(\[m\])?(=\S+?)?\}", "([^/]+)$1")
  routePathStr = routePathStr.replace(re2"\{[a-zA-Z][a-zA-Z0-9_]*(\??)(\[m\])?(=\S+?)?\}", "([^/]+)$1")
  # path param
  routePathStr = routePathStr.replace(re2"\{[a-zA-Z][a-zA-Z0-9_]*:path(\[m\])?\}", "([\\S]+)")
  # regex param
  routePathStr = routePathStr.replace(re2"\{[a-zA-Z][a-zA-Z0-9_]*:/([\s\S]+?)/(\[m\])?\}", "($1)")
  # custom patterns
  var types = ""
  {.cast(gcsafe).}:
    for routeParamType in registeredRouteParamTypes.values():
      routePathStr = routePathStr.replace(
        re2(r"\{[a-zA-Z][a-zA-Z0-9_]*(\??):" & routeParamType.name & r"(\[m\])?(=\S+?)?\}"),
        "(" & routeParamType.pattern & ")$1"
      )
      types &= "|" & routeParamType.name
  # Remove models
  when exportPython:
    routePathStr = routePathStr.replace(re2"\[[a-zA-Z][a-zA-Z0-9_]*(:[a-zA-Z][a-zA-Z0-9_]*)?(\[m\])?(:[a-zA-Z\\-]+)?\]", "")
  else:
    routePathStr = routePathStr.replace(re2"\[[a-zA-Z][a-zA-Z0-9_]*:[a-zA-Z][a-zA-Z0-9_]*(\[m\])?(:[a-zA-Z\\-]+)?\]", "")
  let
    foundPathParams = path.findAll(
      re2(
        r"\{([a-zA-Z][a-zA-Z0-9_]*\??)(:(bool|int|float|string|path|word|/[\s\S]+?/|enum\(\w+\)" &
        types &
        r"))?(\[m\])?(=(\S+?))?\}"
      )
    )
    foundModels =
      when exportPython:
        path.findAll(
          re2"\[([a-zA-Z][a-zA-Z0-9_]*)(:[a-zA-Z][a-zA-Z0-9_]*)?(\[m\])?(:[a-zA-Z\\-]+)?\]"
        )
      else:
        path.findAll(
          re2"\[([a-zA-Z][a-zA-Z0-9_]*):([a-zA-Z][a-zA-Z0-9_]*)(\[m\])?(:[a-zA-Z\\-]+)?\]"
        )
  
  result.purePath = routePathStr

  for pathParam in foundPathParams:
    let
      argTypeStr =
        if pathParam.group(2).len == 0:
          "string"
        else:
          path[pathParam.group(2)]
      defaultVal =
        if pathParam.group(5).len == 0:
          ""
        else:
          path[pathParam.group(5)]
      isMutable = pathParam.group(3).len != 0
    # Detect main data
    var
      name = path[pathParam.group(0)]
      isOptional = false
    # Detect optional value
    if name.endsWith(re2"\?"):
      name = name[0..^2]
      isOptional = true
    elif defaultVal.len > 0:
      isOptional = true
    result.pathParams.add(newPathParamObj(name, argTypeStr, defaultVal, isOptional, isMutable))
    
  for i in foundModels:
    let
      modelName = path[i.group(0)]
      modelType =
        when exportPython:
          if i.group(1).len != 0:
            path[i.group(1)][1..^1]
          else:
            ""
        else:
          path[i.group(1)]
      modelTarget =
        if i.group(3).len != 0:
          path[i.group(3)][1..^1]
        else:
          "JSON"
      isMutable = i.group(2).len != 0
    result.requestModels.add(newRequestModelObj(modelName, modelType, modelTarget, isMutable))


proc exportRouteArgs*(urlPath, routePath, body: NimNode): NimNode =
  ## Finds and exports route arguments
  var path = $routePath
  # Find all declared path params
  for i in path.findAll(re2"<([a-zA-Z][a-zA-Z0-9_]*)>"):
    let name = path[i.group(0)]
    if declaredPathParams.hasKey(name):
      path = path.replace(fmt"<{name}>", declaredPathParams[name])
    else:
      throwDefect(
        HpxPathParamDefect,
        "Unknown path param name: " & name & "\n" & $routePath.toStrLit,
        lineInfoObj(routePath)
      )
  var
    routeData =
      when not exportPython:
        handleRoute(path)
      else:
        RouteDataObj.default
    hasChildren = false
  let
    elifBranch = newNimNode(nnkElifBranch)
    regExp = newCall("re2", newStrLitNode("^" & routeData.purePath & "$"))
  elifBranch.add(newCall("contains", urlPath, regExp), body)
  var idx = 0
  let paramsCount = routeData.pathParams.len
  for i in routeData.pathParams:
    let
      letSection = newNimNode(if i.mutable: nnkVarSection else: nnkLetSection).add(
        newNimNode(nnkIdentDefs).add(ident(i.name), newEmptyNode())
      )
      group = newCall(
        "group",
        newNimNode(nnkBracketExpr).add(
          if routeData.pathParams.len > 1:
            ident"founded_regexp_matches"
          else:
            newCall("findAll", urlPath, regExp),
          newLit(0)
        ),
        newLit(idx)
      )
      foundGroup = newNimNode(nnkBracketExpr).add(urlPath, group)
      # _groupLen < 1
      conditionOptional = newCall("<", newCall("len", group), newIntLitNode(1))
      # _foundGroupLen == 0
      conditionSecondOptional = newCall("==", newCall("len", foundGroup), newIntLitNode(0))

    if i.optional:
      case i.paramType:
      of "bool":
        letSection[0].add(newNimNode(nnkIfStmt).add(
            newNimNode(nnkElifBranch).add(
              conditionOptional,
              newLit(
                if i.defaultValue == "": false else: parseBool(i.defaultValue)
              )
            ),
            newNimNode(nnkElifBranch).add(
              conditionSecondOptional,
              newLit(
                if i.defaultValue == "": false else: parseBool(i.defaultValue)
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
                if i.defaultValue == "": 0 else: parseInt(i.defaultValue)
              )
            ),
            newNimNode(nnkElifBranch).add(
              conditionSecondOptional,
              newLit(
                if i.defaultValue == "": 0 else: parseInt(i.defaultValue)
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
                if i.defaultValue == "": 0.0 else: parseFloat(i.defaultValue)
              )
            ),
            newNimNode(nnkElifBranch).add(
              conditionSecondOptional,
              newLit(
                if i.defaultValue == "": 0.0 else: parseFloat(i.defaultValue)
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
                if i.defaultValue == "": "" else: i.defaultValue
              )
            ),
            newNimNode(nnkElifBranch).add(
              conditionSecondOptional,
              newLit(
                if i.defaultValue == "": "" else: i.defaultValue
              )
            ),
            newNimNode(nnkElse).add(foundGroup)
          )
        )
      else:
        # string Enum
        if ($i.paramType).startsWith("enum"):
          let enumName = ($i.paramType)[5..^2]
          letSection[0].add(newNimNode(nnkIfStmt).add(
            newNimNode(nnkElifBranch).add(
              conditionOptional,
              if i.defaultValue == "":
                newCall("default", ident(enumName))
              else:
                newCall(newNimNode(nnkBracketExpr).add(ident"parseEnum", ident(enumName)), newStrLitNode(i.defaultValue), newCall("default", ident(enumName)))
            ),
            newNimNode(nnkElifBranch).add(
              conditionSecondOptional,
              if i.defaultValue == "":
                newCall("default", ident(enumName))
              else:
                newCall(newNimNode(nnkBracketExpr).add(ident"parseEnum", ident(enumName)), newStrLitNode(i.defaultValue), newCall("default", ident(enumName)))
            ),
            newNimNode(nnkElse).add(
              newCall(newNimNode(nnkBracketExpr).add(ident"parseEnum", ident(enumName)), foundGroup, newCall("default", ident(enumName)))
            )
          ))
        else:
          # custom type
          when not exportPython:
            if $i.paramType in registeredRouteParamTypes:
              var data = registeredRouteParamTypes[$i.paramType]
              letSection[0].add(newCall(data.creator, foundGroup))
            # regex
            else:
              letSection[0].add(foundGroup)
          else:
              letSection[0].add(foundGroup)
    else:
      case i.paramType:
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
        if ($i.paramType).startsWith("enum"):
          let enumName = ($i.paramType)[5..^2]
          letSection[0].add(newCall(newNimNode(nnkBracketExpr).add(ident"parseEnum", ident(enumName)), foundGroup, newCall("default", ident(enumName))))
        else:
          # custom type
          when not exportPython:
            if $i.paramType in registeredRouteParamTypes:
              var data = registeredRouteParamTypes[$i.paramType]
              letSection[0].add(newCall(data.creator, foundGroup))
            # regex
            else:
              letSection[0].add(foundGroup)
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
  for i in routeData.requestModels:
    elifBranch[1].insert(
      0,
      newNimNode(if i.mutable: nnkVarSection else: nnkLetSection).add(
        newIdentDefs(
          ident(i.name),
          newEmptyNode(),
          case i.target.toLower():
          of "json":
            newNimNode(nnkTryStmt).add(
              newCall("jsonTo" & i.typeName, newCall("parseJson", body))
            ).add(newNimNode(nnkExceptBranch).add(
              ident"JsonParsingError",
              newStmtList(
                when defined(debug):
                  newCall("echo", newCall("fmt", newStrLitNode("json parse error: {getCurrentExceptionMsg()}")))
                else:
                  newEmptyNode(),
                newCall("jsonTo" & i.typeName, newCall("newJObject"))
              )
            ))
          of "urlencoded", "x-www-form-urlencoded", "xwwwformurlencoded":
            newCall("xWwwUrlencodedTo" & i.typeName, body)
          of "form-data", "formdata":
            newCall("formDataTo" & i.typeName, body)
          of "xml":
            newCall("xmlBodyTo" & i.typeName, body)
          else:
            newCall("jsonTo" & i.typeName, newCall("newJObject"))
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


when exportPython or defined(docgen):
  proc parseBoolOrJString*(str: string): JsonNode =
    try:
      return newJBool(parseBool(str))
    except Exception:
      return newJString(str)
  proc parseIntOrJString*(str: string): JsonNode =
    try:
      return newJInt(parseInt(str))
    except Exception:
      return newJString(str)
  proc parseFloatOrJString*(str: string): JsonNode =
    try:
      return newJFloat(parseFloat(str))
    except Exception:
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

  proc getRouteParams*(routeData: RouteDataObj, found_regexp_matches: seq[RegexMatch2],
                       urlPath: string = "", handlerParams: seq[HandlerParam] = @[], body: string = "",
                       force: bool = false): PyObject =
    ## Finds and exports route arguments
    var res = pyDict()
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
            when exportPython:
              {.cast(gcsafe).}:
                # custom type
                if $i.paramType in registeredRouteParamTypes:
                  var data = registeredRouteParamTypes[$i.paramType]
                  res[i.name] = callObject(data.creator, foundGroup)
                elif registeredRouteParamTypes.hasObjectWithName($paramType):
                  var data = registeredRouteParamTypes.getObjectWithName($paramType)
                  res[i.name] = callObject(data.creator, foundGroup)
                # regex
                else:
                  res[i.name] = newJString(foundGroup)
            # regex
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
            when exportPython:
              {.cast(gcsafe).}:
                # custom type
                if $i.paramType in registeredRouteParamTypes:
                  var data = registeredRouteParamTypes[$i.paramType]
                  res[i.name] = callObject(data.creator, foundGroup)
                # regex
                else:
                  res[i.name] = newJString(foundGroup)
            # regex
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
          when exportPython:
            {.cast(gcsafe).}:
              # custom type
              if $i.paramType in registeredRouteParamTypes:
                var data = registeredRouteParamTypes[$i.paramType]
                res[i.name] = callObject(data.creator, foundGroup)
              elif registeredRouteParamTypes.hasObjectWithName($paramType):
                var data = registeredRouteParamTypes.getObjectWithName($paramType)
                res[i.name] = callObject(data.creator, foundGroup)
              # regex
              else:
                res[i.name] = newJString(foundGroup)
          # regex
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
          when exportPython:
            {.cast(gcsafe).}:
              # custom type
              if $i.paramType in registeredRouteParamTypes:
                var data = registeredRouteParamTypes[$i.paramType]
                res[i.name] = callObject(data.creator, foundGroup)
              # regex
              else:
                res[i.name] = newJString(foundGroup)
          # regex
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
    return res


proc pathParamsBoilerplate(node: NimNode, kind, regexVal: var string) =
  if node.kind == nnkIdent:
    kind = $node
  # regex type
  elif node.kind == nnkCallStrLit and $node[0] == "re2":
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
  ##      arg2 re2"\d+u"
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
