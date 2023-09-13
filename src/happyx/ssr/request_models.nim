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
  macros,
  macrocache,
  tables,
  strtabs,
  strutils,
  strformat,
  # Happyx
  ../core/[exceptions, constants],
  ../private/macro_utils


const modelFields* = CacheTable"HappyXModelFields"


macro model*(modelName, body: untyped): untyped =
  ## Creates a new request body model
  ## 
  ## Allow:
  ## - [x] JSON
  ## - [x] XML
  ## - [x] Form-Data
  ## - [x] x-www-form-urlencoded
  ## 
  var
    options: seq[string] = @[]
    enableOptions = false
    modelName = modelName
  if modelName.kind == nnkBracketExpr:
    enableOptions = true
    for i in 1..<modelName.len:
      options.add ($modelName[i].toStrLit).toLower()
    modelName = modelName[0]
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
              newCall("hasKey", ident"node", newStrLitNode($argName)),
              newAssignment(
                newDotExpr(ident"result", argName),
                newCall("to", newCall("[]", ident"node", newStrLitNode($argName)), argType)
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
              newCall("hasKey", ident"dataTable", newStrLitNode($argName)),
              newAssignment(
                newDotExpr(ident"result", argName),
                case ($argType.toStrLit).toLower()
                of "int":
                  newCall("parseInt", newCall("[]", ident"dataTable", newStrLitNode($argName)))
                of "float":
                  newCall("parseFloat", newCall("[]", ident"dataTable", newStrLitNode($argName)))
                of "bool":
                  newCall("parseBool", newCall("[]", ident"dataTable", newStrLitNode($argName)))
                of "string":
                  newCall("[]", ident"dataTable", newStrLitNode($argName))
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
              newCall("hasKey", ident"xmlBody", newStrLitNode($argName)),
              newNimNode(nnkTryStmt).add(
                newAssignment(
                  newDotExpr(ident"result", argName),
                  newCall("to", newCall("[]", ident"xmlBody", newStrLitNode($argName)), argType)
                ), newNimNode(nnkExceptBranch).add(
                  ident"JsonKindError",
                  newStmtList(
                      newCall(
                        "error", newCall(
                          "fmt", newStrLitNode(
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
              newCall("hasKey", ident"dataTable", newStrLitNode($argName)),
              newAssignment(
                newDotExpr(ident"result", argName),
                case ($argType.toStrLit).toLower()
                of "int":
                  newCall("parseInt", newCall("[]", ident"dataTable", newStrLitNode($argName)))
                of "float":
                  newCall("parseFloat", newCall("[]", ident"dataTable", newStrLitNode($argName)))
                of "bool":
                  newCall("parseBool", newCall("[]", ident"dataTable", newStrLitNode($argName)))
                of "string":
                  newCall("[]", ident"dataTable", newStrLitNode($argName))
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
              newCall("hasKey", ident"dataTable", newStrLitNode($argName)),
              newAssignment(
                newDotExpr(ident"result", argName),
                newCall("[]", ident"formDataItemsTable", newStrLitNode($argName))
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
              newCall("hasKey", ident"node", newStrLitNode($argName)),
              newAssignment(
                newDotExpr(ident"result", argName),
                newCall("to", newCall("[]", ident"node", newStrLitNode($argName)), argType)
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
              newCall("hasKey", ident"dataTable", newStrLitNode($argName)),
              newAssignment(
                newDotExpr(ident"result", argName),
                case ($argType.toStrLit).toLower()
                of "int":
                  newCall("parseInt", newCall("[]", ident"dataTable", newStrLitNode($argName)))
                of "float":
                  newCall("parseFloat", newCall("[]", ident"dataTable", newStrLitNode($argName)))
                of "bool":
                  newCall("parseBool", newCall("[]", ident"dataTable", newStrLitNode($argName)))
                of "string":
                  newCall("[]", ident"dataTable", newStrLitNode($argName))
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
              newCall("hasKey", ident"xmlBody", newStrLitNode($argName)),
              newNimNode(nnkTryStmt).add(
                newAssignment(
                  newDotExpr(ident"result", argName),
                  newCall("to", newCall("[]", ident"xmlBody", newStrLitNode($argName)), argType)
                ), newNimNode(nnkExceptBranch).add(
                  ident"JsonKindError",
                  newStmtList(
                      newCall(
                        "error", newCall(
                          "fmt", newStrLitNode(
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
              newCall("hasKey", ident"dataTable", newStrLitNode($argName)),
              newAssignment(
                newDotExpr(ident"result", argName),
                case ($argType).toLower()
                of "int":
                  newCall("parseInt", newCall("[]", ident"dataTable", newStrLitNode($argName)))
                of "float":
                  newCall("parseFloat", newCall("[]", ident"dataTable", newStrLitNode($argName)))
                of "bool":
                  newCall("parseBool", newCall("[]", ident"dataTable", newStrLitNode($argName)))
                of "string":
                  newCall("[]", ident"dataTable", newStrLitNode($argName))
                else:
                  newCall("default", argType)
              )
            ))
          else:
            newNimNode(nnkIfStmt).add(
              newNimNode(nnkElifBranch).add(
              newCall("hasKey", ident"dataTable", newStrLitNode($argName)),
              newAssignment(
                newDotExpr(ident"result", argName),
                newCall("[]", ident"formDataItemsTable", newStrLitNode($argName))
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
        newEmptyNode(),
        newNimNode(nnkObjectTy).add(
          newEmptyNode(),  # no pragma
          newNimNode(nnkOfInherit).add(ident"ModelBase"),
          params
        )
      )
    ),
    if not enableOptions or (enableOptions and "json" in options):
      newProc(
        postfix(ident("jsonTo" & $modelName), "*"),
        [modelName, newIdentDefs(ident"node", ident"JsonNode")],
        newStmtList(
          newAssignment(ident"result", newNimNode(nnkObjConstr).add(ident($modelName))),
          if asgnStmt.len > 0: asgnStmt else: newStmtList()
        )
      )
    else:
      newEmptyNode(),
    if not enableOptions or (enableOptions and "xwwwformurlencoded" in options):
      newProc(
        postfix(ident("xWwwUrlencodedTo" & $modelName), "*"),
        [modelName, newIdentDefs(ident"formData", ident"string")],
        newStmtList(
          newAssignment(ident"result", newNimNode(nnkObjConstr).add(ident($modelName))),
          newLetStmt(ident"dataTable", newCall("parseXWwwFormUrlencoded", ident"formData")),
          if asgnStmt.len > 0: asgnUrlencoded else: newStmtList()
        )
      )
    else:
      newEmptyNode(),
    if not enableOptions or (enableOptions and "xml" in options):
      newProc(
        postfix(ident("xmlBodyTo" & $modelName), "*"),
        [modelName, newIdentDefs(ident"data", ident"string")],
        newStmtList(
          newAssignment(ident"result", newNimNode(nnkObjConstr).add(ident($modelName))),
          newLetStmt(ident"xmlBody", newCall("parseXmlBody", ident"data")),
          if asgnStmt.len > 0: asgnXml else: newStmtList()
        )
      )
    else:
      newEmptyNode(),
    if not enableOptions or (enableOptions and "formdata" in options):
      newProc(
        postfix(ident("formDataTo" & $modelName), "*"),
        [modelName, newIdentDefs(ident"data", ident"string")],
        newStmtList(
          newAssignment(ident"result", newNimNode(nnkObjConstr).add(ident($modelName))),
          newNimNode(nnkLetSection).add(newNimNode(nnkVarTuple).add(
            ident"dataTable", ident"formDataItemsTable", newEmptyNode(),
            newCall("parseFormData", ident"data")
          )),
          if asgnStmt.len > 0: asgnFormData else: newStmtList()
        )
      )
    else:
      newEmptyNode(),
  )
  when enableRequestModelDebugMacro:
    echo result.toStrLit
    if reqModelDebugTarget == $modelName:
      quit(QuitSuccess)
