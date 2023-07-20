## # Request Models 🔥
## 
## Provides working with request models
## 
## ## Example
## 
## .. code-block::nim
##    model Message:
##      text: string
##      authorId: int
##    serve "127.0.0.1", 5000:
##      post "/[msg:Message]":
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
  strtabs,
  strutils,
  # Happyx
  ../core/[exceptions, constants],
  ./form_data


macro model*(modelName, body: untyped): untyped =
  ## Creates a new request body model
  ## 
  ## Allow:
  ## - [X] JSON
  ## - [X] Form-Data
  ## - [X] x-www-form-urlencoded
  ## 
  var
    params = newNimNode(nnkRecList)
    asgnStmt = newStmtList()
    asgnUrlencoded = newStmtList()
    asgnFormData = newStmtList()
  
  for i in body:
    if i.kind == nnkCall and i.len == 2 :
      let argName = i[0]
      # arg: type
      if i[1][0].kind in [nnkIdent, nnkBracketExpr]:
        let argType = i[1][0]
        params.add(newIdentDefs(
          postfix(argName, "*"), argType
        ))
        if ($argType).toLower() != "formdataitem":
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
                case ($argType).toLower()
                of "int":
                  newCall("parseInt", newCall("[]", ident"dataTable", newStrLitNode($argName)))
                of "float":
                  newCall("parseFloat", newCall("[]", ident"dataTable", newStrLitNode($argName)))
                of "bool":
                  newCall("parseBool", newCall("[]", ident"dataTable", newStrLitNode($argName)))
                else:
                  newCall("[]", ident"dataTable", newStrLitNode($argName))
              )
            ), newNimNode(nnkElse).add(
              newAssignment(
                newDotExpr(ident"result", argName),
                newCall("default", argType)
              )
            )
          ))
        # form-data
        echo ($argType).toLower()
        asgnFormData.add(
          if ($argType).toLower() != "formdataitem":
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
                else:
                  newCall("[]", ident"dataTable", newStrLitNode($argName))
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
      elif i[1][0].kind == nnkAsgn and i[1][0][0].kind == nnkIdent:
        let
          argType = i[1][0][0]
          argDefault = i[1][0][1]
        params.add(newIdentDefs(
          postfix(argName, "*"), argType
        ))
        if ($argType).toLower() != "formdataitem":
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
                case ($argType).toLower()
                of "int":
                  newCall("parseInt", newCall("[]", ident"dataTable", newStrLitNode($argName)))
                of "float":
                  newCall("parseFloat", newCall("[]", ident"dataTable", newStrLitNode($argName)))
                of "bool":
                  newCall("parseBool", newCall("[]", ident"dataTable", newStrLitNode($argName)))
                else:
                  newCall("[]", ident"dataTable", newStrLitNode($argName))
              )
            )
          ))
        # form-data
        echo ($argType).toLower()
        asgnFormData.add(
          if ($argType).toLower() != "formdataitem":
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
                else:
                  newCall("[]", ident"dataTable", newStrLitNode($argName))
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
    newProc(
      ident("jsonTo" & $modelName),
      [modelName, newIdentDefs(ident"node", ident"JsonNode")],
      newStmtList(
        newAssignment(ident"result", newNimNode(nnkObjConstr).add(ident($modelName))),
        if asgnStmt.len > 0: asgnStmt else: newStmtList()
      )
    ),
    newProc(
      ident("xWwwUrlencodedTo" & $modelName),
      [modelName, newIdentDefs(ident"formData", ident"string")],
      newStmtList(
        newAssignment(ident"result", newNimNode(nnkObjConstr).add(ident($modelName))),
        newLetStmt(ident"dataTable", newCall("parseXWwwFormUrlencoded", ident"formData")),
        if asgnStmt.len > 0: asgnUrlencoded else: newStmtList()
      )
    ),
    newProc(
      ident("formDataTo" & $modelName),
      [modelName, newIdentDefs(ident"data", ident"string")],
      newStmtList(
        newAssignment(ident"result", newNimNode(nnkObjConstr).add(ident($modelName))),
        newNimNode(nnkLetSection).add(newNimNode(nnkVarTuple).add(
          ident"dataTable", ident"formDataItemsTable", newEmptyNode(),
          newCall("parseFormData", ident"data")
        )),
        if asgnStmt.len > 0: asgnFormData else: newStmtList()
      )
    ),
  )
  when enableDebug:
    echo result.toStrLit
