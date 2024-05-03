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
  std/strtabs,
  std/strutils,
  std/strformat,
  # Happyx
  ../core/[exceptions, constants]

when not declared(macrocache.hasKey):
  import ../private/macro_utils


const
  modelFields* = CacheTable"HappyXModelFields"
  modelFieldsGenerics* = CacheTable"HappyXModelFieldsGenerics"


macro model*(modelName, body: untyped): untyped =
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
    enableOptions = false
    modelName = modelName
    generics = newNimNode(nnkGenericParams)
    genericsBracket = modelName.copy()
  # detect generics
  if modelName.kind == nnkBracketExpr:
    # get generics
    var nextGenericParam = newNimNode(nnkIdentDefs)
    genericsBracket = modelName.copy()
    for i in 1..<modelName.len:
      let node = modelName[i]
      if node.kind == nnkIdent:
        nextGenericParam.add(node)
        if i < modelName.len-1:
          continue
        else:
          nextGenericParam.add(newEmptyNode())
      if node.kind == nnkExprColonExpr:
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
    if i.kind == nnkCall and i.len == 2 and i[1].kind == nnkStmtList and i[1].len == 1:
      let argName = i[0]
      # arg: type
      if i[1][0].kind != nnkAsgn:
        let argType = i[1][0]
        params.add(newIdentDefs(
          postfix(argName, "*"), argType
        ))
        modelFields[$modelName].add(newStmtList(argName.toStrLit, argType.toStrLit))
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
          argDefault = i[1][0][1]
        params.add(newIdentDefs(
          postfix(argName, "*"), argType
        ))
        modelFields[$modelName].add(newStmtList(argName.toStrLit, argType.toStrLit))
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
    throwDefect(
      HpxModelSyntaxDefect,
      "Wrong model syntax: ",
      lineInfoObj(i)
    )
  
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
