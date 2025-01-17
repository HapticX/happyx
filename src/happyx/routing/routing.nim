## Provides powerful routing ✨
## 
import
  ./routing/base,
  ./routing/types,
  ./routing/scanfuncs

export
  base,
  types,
  scanfuncs


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
    regex,
    ../bindings/python_types
elif defined(napibuild):
  import
    denim,
    regex,
    ../bindings/node_types
elif exportJvm:
  import
    jnim,
    jnim/private/[jni_wrapper],
    jnim/java/[lang, util],
    regex,
    ../bindings/java_types


when exportJvm:
  import tables




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
