## # Request Models 🔥
## 
## Provides working with request models
## 
## Available `JSON`, `XML`, `form-data` and `x-www-form-urlencoded`.
## 
## ## Example
## 
## .. code-block::nim
##    model Message:
##      text: string
##      authorId: int
##    serve "127.0.0.1", 5000:
##      post "/[msg:Message]":  # by default uses JSON mode
##        return {"response": {
##          "text": msg.text, "author": msg.authorId
##        }}
## 
## 
## ## Modes 🛠
## 
## Request models parses only JSON raw data by default. To use `form-data` or `x-www-form-urlencoded`
## you should enable it in path params
## 
## ### JSON ✨
## 
## This mode used by default
## 
## .. code-block::nim
##    model MyModel:
##      x: int
## 
##    serve "127.0.0.1", 5000:
##      post "/[m:MyModel:json]":
##        return {"response": m.x}
## 
## ### XML ✨
## 
## .. code-block::nim
##    model MyModel:
##      x: int
## 
##    serve "127.0.0.1", 5000:
##      post "/[m:MyModel:xml]":
##        # Body is
##        # <MyModel>
##        #   <x type="int">1000</x>
##        # </MyModel>
##        return {"response": m.x}
## 
## 
## ### Form-Data ✨
## 
## .. code-block::nim
##    model UploadImg:
##      img: FormDataItem  # this field will parse all data from form-data
##      additionalContext: string = ""  # optional string field
##    
##    serve "127.0.0.1", 5000:
##      # Use UploadImg model as form-data model
##      post "/upload/[data:UploadImg:formData]":
##        # working with UploadImg model
##        echo data.img.filename
##        echo data.additionalContext
##        return "Hello"
## 
## ### X-WWW-Form-Urlencoded ✨
## 
## .. code-block::nim
##    model Query:
##      author: int
##      additionalContext: string = ""  # optional string field
##    
##    serve "127.0.0.1", 5000:
##      # Use Query model as x-www-form-urlencoded model
##      post "/upload/[data:Query:urlencoded]":
##        # working with Query model
##        echo data.author
##        echo data.additionalContext
##        return "Hello"
##

import
  # stdlib
  std/macros,
  std/macrocache,
  std/strutils,
  std/strformat,
  # Happyx
  ../core/[exceptions, constants]

when not declared(macrocache.hasKey):
  import ../private/macro_utils


const
  modelFields* = CacheTable"HappyXModelFields"
  modelFieldsGenerics* = CacheTable"HappyXModelFieldsGenerics"
  builtinTypes* = [
    "char", "byte", "int8", "int16", "int32", "int64", "int",
    "float", "float32", "float64", "string", "formdataitem",
    "cdouble", "cfloat", "cint", "cstring"
  ]


proc modelImpl(modelName: NimNode, enableOptions: bool, options: seq[string], generics, genericsBracket, body: NimNode): NimNode =
  ## Low-level API model implementation
  if modelName.kind != nnkIdent:
    throwDefect(
      HpxModelSyntaxDefect,
      "Incorrect request model structure: model name should be identifier! ",
      lineInfoObj(modelName)
    )
  var
    params = newNimNode(nnkRecList)
    asgnStmt = newStmtList()
    asgnUrlencoded = newStmtList()
    asgnFormData = newStmtList()
    asgnXml = newStmtList()
  
  if modelFields.hasKey($modelName):
    throwDefect(
      HpxModelSyntaxDefect,
      fmt"Request model '{modelName}' already exists. ",
      lineInfoObj(modelName)
    )
  modelFields[$modelName] = newStmtList()
  modelFieldsGenerics[$modelName] = newLit(generics.kind != nnkEmpty)
  for i in body:
    let argName = i[0]
    # arg: type
    if i[1].len == 1:
      let argType = i[1][0]
      params.add(newIdentDefs(
        postfix(argName, "*"), argType
      ))
      modelFields[$modelName].add(newStmtList(argName.toStrLit, argType.toStrLit, newLit(true)))
      let argStr = $argType.toStrLit
      if argStr.toLower notin builtinTypes and argType.typeKind != ntyNone:
        if argType.getTypeImpl()[1].kind == nnkSym:
          let typeImpl = argType.getTypeImpl()[1].getImpl
          if typeImpl[2].kind == nnkEnumTy:
            let name = typeImpl[0].toStrLit
            modelFields[$name] = newStmtList()
            modelFieldsGenerics[$name] = newLit(true)
            for i in 1..<typeImpl[2].len:
              if typeImpl[2][i].len == 2:
                modelFields[$name].add(newStmtList(typeImpl[2][i][0].toStrLit, typeImpl[2][i][1]))
              else:
                modelFields[$name].add(newStmtList(typeImpl[2][i].toStrLit, typeImpl[2][i].toStrLit))
      if argStr.toLower() != "formdataitem":
        # JSON raw data
        asgnStmt.add(newNimNode(nnkIfStmt).add(
          newNimNode(nnkElifBranch).add(
            newCall("hasKey", ident"node", newLit($argName)),
            newAssignment(
              newDotExpr(ident"result", argName),
              newCall("to", newCall("[]", ident"node", newLit($argName)), argType)
            )
          ), newNimNode(nnkElse).add(
            newAssignment(
              newDotExpr(ident"result", argName),
              newCall("default", argType)
            )
          )
        ))
        # x-www-form-urlencode
        asgnUrlencoded.add(newNimNode(nnkIfStmt).add(
          newNimNode(nnkElifBranch).add(
            newCall("hasKey", ident"dataTable", newLit($argName)),
            newAssignment(
              newDotExpr(ident"result", argName),
              case ($argType.toStrLit).toLower()
              of "int":
                newCall("parseInt", newCall("[]", ident"dataTable", newLit($argName)))
              of "float":
                newCall("parseFloat", newCall("[]", ident"dataTable", newLit($argName)))
              of "bool":
                newCall("parseBool", newCall("[]", ident"dataTable", newLit($argName)))
              of "string":
                newCall("[]", ident"dataTable", newLit($argName))
              else:
                newCall("default", argType)
            )
          ), newNimNode(nnkElse).add(
            newAssignment(
              newDotExpr(ident"result", argName),
              newCall("default", argType)
            )
          )
        ))
        # XML
        asgnXml.add(newNimNode(nnkIfStmt).add(
          newNimNode(nnkElifBranch).add(
            newCall("hasKey", ident"xmlBody", newLit($argName)),
            newNimNode(nnkTryStmt).add(
              newAssignment(
                newDotExpr(ident"result", argName),
                newCall("to", newCall("[]", ident"xmlBody", newLit($argName)), argType)
              ), newNimNode(nnkExceptBranch).add(
                ident"JsonKindError",
                newStmtList(
                    newCall(
                      "error", newCall(
                        "fmt", newLit(
                          fmt"Couldn't parse XML model ({modelName}.{argName}: {argType.toStrLit}) - " & "{getCurrentExceptionMsg()}"))
                    ),
                )
              )
            )
          ), newNimNode(nnkElse).add(
            newAssignment(
              newDotExpr(ident"result", argName),
              newCall("default", argType)
            )
          ))
        )
      # form-data
      asgnFormData.add(
        if ($argType.toStrLit).toLower() != "formdataitem":
          newNimNode(nnkIfStmt).add(
            newNimNode(nnkElifBranch).add(
            newCall("hasKey", ident"dataTable", newLit($argName)),
            newAssignment(
              newDotExpr(ident"result", argName),
              case ($argType.toStrLit).toLower()
              of "int":
                newCall("parseInt", newCall("[]", ident"dataTable", newLit($argName)))
              of "float":
                newCall("parseFloat", newCall("[]", ident"dataTable", newLit($argName)))
              of "bool":
                newCall("parseBool", newCall("[]", ident"dataTable", newLit($argName)))
              of "string":
                newCall("[]", ident"dataTable", newLit($argName))
              else:
                newCall("default", argType)
            )
          ), newNimNode(nnkElse).add(
            newAssignment(
              newDotExpr(ident"result", argName),
              newCall("default", argType)
            )
          ))
        else:
          newNimNode(nnkIfStmt).add(
            newNimNode(nnkElifBranch).add(
            newCall("hasKey", ident"dataTable", newLit($argName)),
            newAssignment(
              newDotExpr(ident"result", argName),
              newCall("[]", ident"formDataItemsTable", newLit($argName))
            )
          ), newNimNode(nnkElse).add(
            newAssignment(
              newDotExpr(ident"result", argName),
              newCall("default", argType)
            )
          ))
      )
      continue
    # arg: type = default
    else:
      let
        argType = i[1][0][0]
        argDefault = i[1][1][0]
      params.add(newIdentDefs(
        postfix(argName, "*"), argType
      ))
      modelFields[$modelName].add(newStmtList(argName.toStrLit, argType.toStrLit))
      let argStr = $argType.toStrLit
      if argStr.toLower notin builtinTypes and argType.typeKind != ntyNone:
        if argType.getTypeImpl()[1].kind == nnkSym:
          let typeImpl = argType.getTypeImpl()[1].getImpl
          if typeImpl[2].kind == nnkEnumTy:
            let name = typeImpl[0].toStrLit
            modelFields[$name] = newStmtList()
            modelFieldsGenerics[$name] = newLit(true)
            for i in 1..<typeImpl[2].len:
              if typeImpl[2][i].len == 2:
                modelFields[$name].add(newStmtList(typeImpl[2][i][0].toStrLit, typeImpl[2][i][1]))
              else:
                modelFields[$name].add(newStmtList(typeImpl[2][i].toStrLit, typeImpl[2][i].toStrLit))
      if ($argType.toStrLit).toLower() != "formdataitem":
        # JSON raw data
        asgnStmt.add(newNimNode(nnkIfStmt).add(
          newNimNode(nnkElifBranch).add(
            newCall("hasKey", ident"node", newLit($argName)),
            newAssignment(
              newDotExpr(ident"result", argName),
              newCall("to", newCall("[]", ident"node", newLit($argName)), argType)
            )
          ), newNimNode(nnkElse).add(
            newAssignment(
              newDotExpr(ident"result", argName),
              argDefault
            )
          )
        ))
        # x-www-form-urlencode
        asgnUrlencoded.add(newNimNode(nnkIfStmt).add(
          newNimNode(nnkElifBranch).add(
            newCall("hasKey", ident"dataTable", newLit($argName)),
            newAssignment(
              newDotExpr(ident"result", argName),
              case ($argType.toStrLit).toLower()
              of "int":
                newCall("parseInt", newCall("[]", ident"dataTable", newLit($argName)))
              of "float":
                newCall("parseFloat", newCall("[]", ident"dataTable", newLit($argName)))
              of "bool":
                newCall("parseBool", newCall("[]", ident"dataTable", newLit($argName)))
              of "string":
                newCall("[]", ident"dataTable", newLit($argName))
              else:
                newCall("default", argType)
            )
          ), newNimNode(nnkElse).add(
            newAssignment(
              newDotExpr(ident"result", argName),
              argDefault
            )
          )
        ))
        # XML
        asgnXml.add(newNimNode(nnkIfStmt).add(
          newNimNode(nnkElifBranch).add(
            newCall("hasKey", ident"xmlBody", newLit($argName)),
            newNimNode(nnkTryStmt).add(
              newAssignment(
                newDotExpr(ident"result", argName),
                newCall("to", newCall("[]", ident"xmlBody", newLit($argName)), argType)
              ), newNimNode(nnkExceptBranch).add(
                ident"JsonKindError",
                newStmtList(
                    newCall(
                      "error", newCall(
                        "fmt", newLit(
                          fmt"Couldn't parse XML model ({modelName}.{argName}: {argType.toStrLit}) - " & "{getCurrentExceptionMsg()}"))
                    ),
                )
              )
            )
          ), newNimNode(nnkElse).add(
            newAssignment(
              newDotExpr(ident"result", argName),
              argDefault
            )
          ))
        )
      # form-data
      asgnFormData.add(
        if ($argType.toStrLit).toLower() != "formdataitem":
          newNimNode(nnkIfStmt).add(
            newNimNode(nnkElifBranch).add(
            newCall("hasKey", ident"dataTable", newLit($argName)),
            newAssignment(
              newDotExpr(ident"result", argName),
              case ($argType).toLower()
              of "int":
                newCall("parseInt", newCall("[]", ident"dataTable", newLit($argName)))
              of "float":
                newCall("parseFloat", newCall("[]", ident"dataTable", newLit($argName)))
              of "bool":
                newCall("parseBool", newCall("[]", ident"dataTable", newLit($argName)))
              of "string":
                newCall("[]", ident"dataTable", newLit($argName))
              else:
                newCall("default", argType)
            )
          ))
        else:
          newNimNode(nnkIfStmt).add(
            newNimNode(nnkElifBranch).add(
            newCall("hasKey", ident"dataTable", newLit($argName)),
            newAssignment(
              newDotExpr(ident"result", argName),
              newCall("[]", ident"formDataItemsTable", newLit($argName))
            )
          ))
      )
      continue

  result = newStmtList(
    newNimNode(nnkTypeSection).add(
      newNimNode(nnkTypeDef).add(
        postfix(ident($modelName), "*"),  # name
        generics,
        newNimNode(nnkObjectTy).add(
          newEmptyNode(),  # no pragma
          newNimNode(nnkOfInherit).add(ident"ModelBase"),
          params
        )
      )
    ),
    if not enableOptions or (enableOptions and "json" in options):
      let x = newProc(
        postfix(ident("jsonTo" & $modelName), "*"),
        [genericsBracket, newIdentDefs(ident"node", ident"JsonNode")],
        newStmtList(
          newAssignment(ident"result", newNimNode(nnkObjConstr).add(genericsBracket)),
          if asgnStmt.len > 0: asgnStmt else: newStmtList()
        )
      )
      x[2] = generics
      x
    else:
      newEmptyNode(),
    if not enableOptions or (enableOptions and "xwwwformurlencoded" in options):
      let x = newProc(
        postfix(ident("xWwwUrlencodedTo" & $modelName), "*"),
        [genericsBracket, newIdentDefs(ident"formData", ident"string")],
        newStmtList(
          newAssignment(ident"result", newNimNode(nnkObjConstr).add(genericsBracket)),
          newLetStmt(ident"dataTable", newCall("parseXWwwFormUrlencoded", ident"formData")),
          if asgnStmt.len > 0: asgnUrlencoded else: newStmtList()
        )
      )
      x[2] = generics
      x
    else:
      newEmptyNode(),
    if not enableOptions or (enableOptions and "xml" in options):
      let x = newProc(
        postfix(ident("xmlBodyTo" & $modelName), "*"),
        [genericsBracket, newIdentDefs(ident"data", ident"string")],
        newStmtList(
          newAssignment(ident"result", newNimNode(nnkObjConstr).add(genericsBracket)),
          newLetStmt(ident"xmlBody", newCall("parseXmlBody", ident"data")),
          if asgnStmt.len > 0: asgnXml else: newStmtList()
        )
      )
      x[2] = generics
      x
    else:
      newEmptyNode(),
    if not enableOptions or (enableOptions and "formdata" in options):
      let x = newProc(
        postfix(ident("formDataTo" & $modelName), "*"),
        [genericsBracket, newIdentDefs(ident"data", ident"string")],
        newStmtList(
          newAssignment(ident"result", newNimNode(nnkObjConstr).add(genericsBracket)),
          newNimNode(nnkLetSection).add(newNimNode(nnkVarTuple).add(
            ident"dataTable", ident"formDataItemsTable", newEmptyNode(),
            newCall("parseFormData", ident"data")
          )),
          if asgnStmt.len > 0: asgnFormData else: newStmtList()
        )
      )
      x[2] = generics
      x
    else:
      newEmptyNode(),
  )
  # echo treeRepr result
  when enableRequestModelDebugMacro:
    echo result.toStrLit
    if reqModelDebugTarget == $modelName:
      quit(QuitSuccess)


macro modelImplementation*(modelName: untyped, enableOptions: static[bool], options: static[seq[string]], generics, genericsBracket: untyped, body: typed): untyped =
  modelImpl(modelName, enableOptions, options, generics, genericsBracket, body)


macro modelImplementationUntyped*(modelName: untyped, enableOptions: static[bool], options: static[seq[string]], generics, genericsBracket: untyped, body: untyped): untyped =
  modelImpl(modelName, enableOptions, options, generics, genericsBracket, body)


macro model*(name, body: untyped): untyped =
  ## Creates a new request body model
  ## 
  ## Allow:
  ## - [x] JSON
  ## - [x] XML
  ## - [x] Form-Data
  ## - [x] x-www-form-urlencoded
  ## 
  ## ## Example:
  ## 
  ## Simple user model.
  ## Supports all models (JSON, XML, Form-Data and x-www-form-urlencoded).
  ## ```nim
  ## model User:
  ##   id: int
  ##   username: string
  ## ```
  ## 
  ## Simple user model.
  ## Supports `JSON` and `XML`.
  ## ```nim
  ## model User{JSON, XML}:
  ##   id: int
  ##   username: string
  ## ```
  ## 
  ## Simple user model with **generics**.
  ## Supports all models (JSON, XML, Form-Data and x-www-form-urlencoded).
  ## ```nim
  ## model User[T]:
  ##   id: T
  ##   username: string
  ## ```
  ## 
  ## Simple user model with **generics**.
  ## Supports JSON and XML.
  ## ```nim
  ## model User{JSON, XML}[T]:
  ##   id: T
  ##   username: string
  ## ```
  ## 
  var
    options: seq[string] = @[]
    genericsNames: seq[string] = @[]
    enableOptions = false
    modelName = name
    generics = newNimNode(nnkGenericParams)
    genericsBracket = name.copy()
  # detect generics
  if modelName.kind == nnkBracketExpr:
    # get generics
    var nextGenericParam = newNimNode(nnkIdentDefs)
    genericsBracket = modelName.copy()
    for i in 1..<modelName.len:
      let node = modelName[i]
      if node.kind == nnkIdent:
        nextGenericParam.add(node)
        genericsNames.add($node)
        if i < modelName.len-1:
          continue
        else:
          nextGenericParam.add(newEmptyNode())
      if node.kind == nnkExprColonExpr:
        genericsNames.add($node[0])
        nextGenericParam.add(node[0], node[1])
      nextGenericParam.add(newEmptyNode())
      generics.add(nextGenericParam.copy())
      nextGenericParam = newNimNode(nnkIdentDefs)
    # detect options
    if modelName[0].kind == nnkCurlyExpr:
      genericsBracket[0] = genericsBracket[0][0]
      enableOptions = true
      for i in 1..<modelName[0].len:
        options.add ($modelName[0][i].toStrLit).toLower()
      modelName = modelName[0][0]
    elif modelname[0].kind == nnkIdent:
      modelName = modelName[0]
  # detect options
  elif modelName.kind == nnkCurlyExpr:
    enableOptions = true
    for i in 1..<modelName.len:
      options.add ($modelName[i].toStrLit).toLower()
    modelName = modelName[0]
  if generics.len == 0:
    generics = newEmptyNode()
  
  result = newCall(
    "modelImplementation",
    modelName, newLit(enableOptions), newLit(options), generics, genericsBracket,
    newNimNode(nnkTupleConstr)
  )
  for i in body:
    if i.kind == nnkCall and i.len == 2 and i[1].kind == nnkStmtList and i[1].len == 1:
      if i[1][0].kind == nnkAsgn:
        result[^1].add(newNimNode(nnkExprColonExpr).add(i[0], newNimNode(nnkTupleConstr).add(
          newNimNode(nnkBracket).add(i[1][0][0]),
          newNimNode(nnkBracket).add(i[1][0][1])
        )))
        if ($i[1][0][1].toStrLit) in genericsNames:
          result[0] = ident"modelImplementationUntyped"
      else:
        result[^1].add(newNimNode(nnkExprColonExpr).add(i[0], newNimNode(nnkBracket).add(i[1][0])))
        if ($i[1][0].toStrLit) in genericsNames:
          result[0] = ident"modelImplementationUntyped"
      continue
    throwDefect(
      HpxModelSyntaxDefect,
      "Wrong model syntax: ",
      lineInfoObj(i)
    )
  # echo result.toStrLit
