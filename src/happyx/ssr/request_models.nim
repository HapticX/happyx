## # Queries 🔥
## 
## Provides working with queries
## 
## ## Example
## 
## .. code-block::nim
##    serve("127.0.0.1", 5000):
##      get "/":
##        id::int = 10
##        echo id
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
  ## - [ ] Form-Data
  ## - [ ] x-www-form-urlencoded
  ## 
  var
    params = newNimNode(nnkRecList)
    asgnStmt = newStmtList()
    asgnUrlencoded = newStmtList()
  
  for i in body:
    if i.kind == nnkCall and i.len == 2 :
      let argName = i[0]
      # arg: type
      if i[1][0].kind in [nnkIdent, nnkBracketExpr]:
        let argType = i[1][0]
        params.add(newIdentDefs(
          postfix(argName, "*"), argType
        ))
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
        continue
      # arg: type = default
      elif i[1][0].kind == nnkAsgn and i[1][0][0].kind == nnkIdent:
        let
          argType = i[1][0][0]
          argDefault = i[1][0][1]
        params.add(newIdentDefs(
          postfix(argName, "*"), argType
        ))
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
            newCall("hasKey", ident"xWwwUrlencodedTable", newStrLitNode($argName)),
            newAssignment(
              newDotExpr(ident"result", argName),
              case ($argType).toLower()
              of "int":
                newCall("parseInt", newCall("[]", ident"xWwwUrlencodedTable", newStrLitNode($argName)))
              of "float":
                newCall("parseFloat", newCall("[]", ident"xWwwUrlencodedTable", newStrLitNode($argName)))
              of "bool":
                newCall("parseBool", newCall("[]", ident"xWwwUrlencodedTable", newStrLitNode($argName)))
              else:
                newCall("[]", ident"xWwwUrlencodedTable", newStrLitNode($argName))
            )
          )
        ))
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
        newLetStmt(ident"xWwwUrlencodedTable", newCall("parseXWwwFormUrlencoded", ident"formData")),
        if asgnStmt.len > 0: asgnUrlencoded else: newStmtList()
      )
    ),
  )
  when enableDebug:
    echo result.toStrLit


# ------WebKitFormBoundary4UxTJlWbkrmPNAYe
# Content-Disposition: form-data; name="x"
# 
# 100
# ------WebKitFormBoundary4UxTJlWbkrmPNAYe
# Content-Disposition: form-data; name="y"
# 
# Hello, world!
# ------WebKitFormBoundary4UxTJlWbkrmPNAYe
# Content-Disposition: form-data; name="img"; filename="depth-blue-aerugo-1x.png"
# Content-Type: image/png
# 
# PNG
# 
# IHDR%W3l0PLTE!#-& :02MDJe]h||$.5/H\Fdadz pHYs+DAc`TvM\}=
#                                                         U��pIENDB`
# ------WebKitFormBoundary4UxTJlWbkrmPNAYe--
# 