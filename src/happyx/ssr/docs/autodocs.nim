## # AutoDocs Module 🐥
## 
## Helpful macro utils to generate autodocumentation
## 
import
  # stdlib
  std/macros,
  std/macrocache,
  std/strutils,
  std/json,
  # thirdparty
  regex,
  # happyx
  ../../routing/[routing, mounting],
  ../../private/macro_utils,
  ../../core/constants,
  ../request_models,
  ./api_doc_template



proc fetchPathParams*(route: var string): tuple[pathParams, models: NimNode] =
  var
    params = newNimNode(nnkBracket)
    models = newNimNode(nnkBracket)
    routeData = handleRoute(route)
  for i in routeData.pathParams:
    params.add(newCall(
      "newPathParamObj",
      newLit(i.name),
      newLit(i.paramType),
      newLit(i.defaultValue),
      newLit(i.optional),
    ))

  for i in routeData.requestModels:
    models.add(newCall(
      "newRequestModelObj",
      newLit(i.name),
      newLit(i.typeName),
      newLit(i.target),
    ))
  
  # Clear route
  route = routeData.path
  route = route.replace(
    re2"\{([a-zA-Z][a-zA-Z0-9_]*)\??(:(bool|int|float|string|path|word|/[\s\S]+?/|enum\(\w+\)))?(\[m\])?(=(\S+?))?\}",
    "{$1}"
  )
  route = route.replace(re2"\[([a-zA-Z][a-zA-Z0-9_]*):([a-zA-Z][a-zA-Z0-9_]*)(\[m\])?(:[a-zA-Z\\-]+)?\]", "")

  (newCall("@", params), newCall("@", models))


proc fetchModelFields*(): NimNode =
  var res = newNimNode(nnkTableConstr)

  for key, val in modelFields.pairs():
    var tableConstr = newNimNode(nnkTableConstr)
    for field in val:
      tableConstr.add(newNimNode(nnkExprColonExpr).add(field[0], field[1]))
    if tableConstr.len > 0:
      res.add(newNimNode(nnkExprColonExpr).add(newLit(key), newCall("newStringTable", tableConstr)))

  if res.len > 0:
    newCall("toTable", res)
  else:
    newCall(newNimNode(nnkBracketExpr).add(
      ident"initTable", ident"string", ident"StringTableRef"
    ))

proc genApiDoc*(body: var NimNode): NimNode =
  ## Returns API route
  var
    docsData = newNimNode(nnkBracket)
    bodyCopy = body.copy()
  bodyCopy.findAndReplaceMount()
  for i in bodyCopy:
    if i.kind in [nnkCall, nnkCommand]:
      if i[0].kind == nnkIdent and i.len == 3 and i[2].kind == nnkStmtList and i[1].kind == nnkStrLit:
        ## HTTP Method
        var
          description = ""
          pathParam = $i[1]
          (params, models) = fetchPathParams(pathParam)
        for statement in i[2]:
          if statement.kind == nnkCommentStmt:
            description &= $statement & "\n"
        docsData.add(newCall(
          "newApiDocObject",
          newCall("@", bracket(newLit(($i[0].toStrLit).toUpper()))),  # HTTP Method
          newLit(description),  # Description
          newLit(pathParam),  # Path
          params, models
        ))
      elif i[0].kind == nnkStrLit and i.len == 2 and i[1].kind == nnkStmtList:
        ## HTTP Method
        var
          description = ""
          pathParam = $i[0]
          (params, models) = fetchPathParams(pathParam)
        for statement in i[1]:
          if statement.kind == nnkCommentStmt:
            description &= $statement & "\n"
        docsData.add(newCall(
          "newApiDocObject",
          newCall("@", bracket(newLit"")),  # HTTP Method
          newLit(description),  # Description
          newLit(pathParam),  # Path
          params, models
        ))
      
  # Get all documentation
  body.add(newNimNode(nnkCommand).add(ident"get", newLit(
    if apiDocsPath.startsWith("/"):
      apiDocsPath
    else:
      "/" & apiDocsPath
  ), newStmtList(
    newCall("answerHtml", ident"req", newCall("renderDocsProcedure")),
  )))
  when not exportPython:
    body.add(newNimNode(nnkCommand).add(ident"get", newLit(
      if apiDocsPath.startsWith("/"):
        apiDocsPath & "/openapi.json"
      else:
        "/" & apiDocsPath & "/openapi.json"
    ), newStmtList(
      newCall("answerJson", ident"req", newCall("openApiJson")),
    )))
  newCall("@", docsData)


proc procApiDocs*(docsData: NimNode): NimNode =
  newStmtList(
    when defined(napibuild):
      newLetStmt(ident"title", newDotExpr(ident"self", ident"title"))
    else:
      newLetStmt(ident"title", newLit(appName)),
    newNimNode(when exportPython or defined(docgen) or defined(napibuild): nnkVarSection else: nnkLetSection).add(
      newIdentDefs(
        ident"apiDocData", newNimNode(nnkBracketExpr).add(ident"seq", ident"ApiDocObject"), docsData
      )
    ),
    when exportPython or defined(docgen):
      newNimNode(nnkForStmt).add(
        ident"route", newDotExpr(ident"self", ident"routes"),
        newNimNode(nnkIfStmt).add(newNimNode(nnkElifBranch).add(
          newCall(
            "not",
            newCall(
              "hasHttpMethod",
              ident"route",
              newCall("@", bracket(newLit"MIDDLEWARE", newLit"NOTFOUND")),
            )
          ),
          newStmtList(
            # Declare RouteData
            newVarStmt(ident"routeData", newCall("handleRoute", newDotExpr(ident"route", ident"path"))),
            newNimNode(nnkIfStmt).add(
              newNimNode(nnkElifBranch).add(
                newCall("==", newDotExpr(ident"route", ident"httpMethod"), newCall("@", bracket(newLit"STATICFILE"))),
                newStmtList(
                  # Declare string (for documentation)
                  newVarStmt(
                    ident"documentation",
                    newCall(
                      "&",
                      newLit"Fetch file from directory: ",
                      newDotExpr(ident"route", ident"purePath")
                    )
                  ),
                  newCall("add", ident"apiDocData", newCall(
                    "newApiDocObject",
                    newCall("@", bracket(newLit"GET")),
                    ident"documentation",
                    newDotExpr(ident"routeData", ident"path"),
                    newDotExpr(ident"routeData", ident"pathParams"),
                    newDotExpr(ident"routeData", ident"requestModels"),
                  ))
                )
              ),
              newNimNode(nnkElse).add(newStmtList(
                # Declare route handler
                newVarStmt(ident"handler", newDotExpr(ident"route", ident"handler")),
                newLetStmt(ident"pDoc", newCall("getAttr", ident"handler", newLit"__doc__")),
                # Declare string (for documentation)
                newVarStmt(ident"documentation", newLit""),
                # Convert __doc__ to string
                newNimNode(nnkIfStmt).add(newNimNode(nnkElifBranch).add(
                  newCall("!=", ident"pDoc", newDotExpr(ident"py", ident"None")),
                  newCall(ident"pyValueToNim", newCall("privateRawPyObj", ident"pDoc"), ident"documentation"),
                )),
                newCall("add", ident"apiDocData", newCall(
                  "newApiDocObject",
                  newDotExpr(ident"route", ident"httpMethod"),
                  ident"documentation",
                  newDotExpr(ident"routeData", ident"path"),
                  newDotExpr(ident"routeData", ident"pathParams"),
                  newDotExpr(ident"routeData", ident"requestModels"),
                ))
              ))
            )
          )),
        )
      )
    elif defined(napibuild):
      newCall("handleApiDoc", ident"self")
    else:
      newEmptyNode(),
    newNimNode(nnkLetSection).add(
      newIdentDefs(
        ident"modelsData",
        newNimNode(nnkBracketExpr).add(
          ident"Table", ident"string", ident"StringTableRef"
        ),
        fetchModelFields()
      )
    ),
  )


proc happyxDocs*(docsData: NimNode): NimNode =
  ## Procedure that helps to generate docs route for HappyX
  procApiDocs(docsData).add(
    newCall("compileTemplateStr", newLit(IndexApiDocPageTemplate))
  )


proc openApiDocs*(docsData: NimNode): NimNode =
  ## Procedure that helps to generate docs route for OpenAPI
  let
    modelsTable = newNimNode(nnkTableConstr)
    examplesTable = newNimNode(nnkTableConstr)
  for k, v in modelFields.pairs():
    let table = newNimNode(nnkTableConstr)
    for s in v.children:
      table.add(newColonExpr(s[0], s[1]))
    modelsTable.add(
      newNimNode(nnkExprColonExpr).add(
        newLit(k), table
      )
    )
    examplesTable.add(
      newNimNode(nnkExprColonExpr).add(
        newLit(k),
        if modelFieldsGenerics[k].boolVal:
          newCall("%*", newLit"")
        else:
          newCall("%*", newNimNode(nnkObjConstr).add(ident(k)))
      )
    )
  let
    modelFieldsStatement = newLetStmt(
      ident"modelsData",
      newCall("%*", modelsTable)
    )
    examplesStatement = newLetStmt(
      ident"examples",
      newCall("%*", examplesTable)
    )
  
  # Result
  procApiDocs(docsData).add(
    quote do:
      if fileExists("openapi.json"):
        return parseFile("openapi.json")
      else:
        result = %*{
          "openapi": "3.1.0",
          "swagger": "2.0",
          "info": {"title": "HappyX OpenAPI Docs", "version": "1.0.0"},
          "paths": {},
          "components": {
            "schemas": {},
            "parameters": {},
            "responses": {},
            "securitySchemas": {},
            "headers": {},
            "links": {},
            "callbacks": {},
            "pathItems": {},
            "examples": {},
            "requestBodies": {}
          }
        }
        `modelFieldsStatement`
        `examplesStatement`
        var matches: RegexMatch2
        # Components schema
        for k, v in modelsData.pairs:
          var schema = %*{
            "type": "object",
            "properties": {}
          }
          for name, value in v.pairs:
            let strValue = value.getStr
            # atomic types
            case strValue
            of "int8", "int16", "int32":
              schema["properties"][name] = %*{"type": "number", "format": "int32"}
            of "int", "int64":
              schema["properties"][name] = %*{"type": "number", "format": "int64"}
            of "float", "float64":
              schema["properties"][name] = %*{"type": "number", "format": "double"}
            of "float32":
              schema["properties"][name] = %*{"type": "number", "format": "float"}
            of "bool":
              schema["properties"][name] = %*{"type": "boolean"}
            of "string":
              schema["properties"][name] = %*{"type": "string"}

            # complex types
            if strValue.find(re2"(seq|array|openarray|varargs)\[([^\]]+)\]", matches):
              schema["properties"][name] = %*{"type": "array", "items": {"type": strValue[matches.group(1)]}}
          
          result["components"]["schemas"][k] = schema

        for route in apiDocData:
          # Skip useless routes
          if route.httpMethod[0] in ["MIDDLEWARE", "STATICFILE", "STATIC", "NOTFOUND"]:
            continue
          result["paths"][route.path] = %*{}
          result["components"][route.path] = %*{}
          let decscription = route.description.replace(
            re2"@openapi\s*\{(\s*\w+\s*[^\n]+|\s*@(params|responses)\s*\{[^\}]+?}\s*)+\s*\}", ""
          )
          var pathData = %*{
            "description": decscription,
            "parameters": [],
            "requestBody": {},
            "responses": {}
          }
          
          if route.description.find(
            re2"@openapi\s*\{((\s*\w+\s*[^\n]+|\s*@(params|responses)\s*\{[^\}]+?}\s*)+)\s*\}",
            matches
          ):
            let text = route.description[matches.group(0)]
            # Additional data
            for m in text.findAll(re2"(?m)^\s*(\w[\w\d_]*)\s*=\s*([^\n]+)$"):
              pathData[text[m.group(0)]] = %text[m.group(1)]
            # Params
            for p in route.pathParams:
              let param = %*{
                "name": p.name,
                "required": not p.optional,
                "in": "path",
                "schema": {
                  "type": p.paramType
                }
              }
              pathData["parameters"].add(param)

            var paramMatches: RegexMatch2
            if text.find(re2"@params\s*{((\s*\w[\w\d]*\!?\s*(:\s*\w+)?[^\n]+)+)\s*}", paramMatches):
              let paramText = text[paramMatches.group(0)]
              for m in paramText.findAll(
                re2"(?m)^\s*(\w[\w\d_]*)(!)?\s*(:\s*\w[\w\d]*)?(\s*\-\s*[^\n]+)?"
              ):
                let param = %*{
                  "name": paramText[m.group(0)],
                  "required": m.group(1).len != 0,
                  "description":
                    if m.group(3).len != 0:
                      strutils.strip(paramText[m.group(3)].replace("-", ""))
                    else:
                      "",
                  "in": "query",
                  "schema": {
                    "type":
                      if m.group(2).len != 0:
                        strutils.strip(paramText[m.group(2)].replace(":", ""))
                      else:
                        "string"
                  }
                }
                var hasParam = false
                for p in 0..<pathData["parameters"].len:
                  if pathData["parameters"][p]["name"] == param["name"]:
                    pathData["parameters"][p]["schema"] = param["schema"]
                    pathData["parameters"][p]["description"] = param["description"]
                    hasParam = true
                    break
                if not hasParam:
                  pathData["parameters"].add(param)
          
          for m in route.models:
            echo m
            let schema = %*{
              "schema": {
                "$ref": "#/components/schemas/" & m.typeName
              },
              "examples": {
                m.typeName: {
                  "value": examples[m.typeName]
                }
              }
            }
            case m.target
            of "JSON":
              pathData["requestBody"]["content"] = %{
                "application/json": schema
              }
            of "XML":
              pathData["requestBody"]["content"] = %{
                "application/xml": schema
              }
            of "Form-Data":
              pathData["requestBody"]["content"] = %{
                "multipart/form-data": schema
              }
            of "x-www-form-urlencoded":
              pathData["requestBody"]["content"] = %{
                "application/x-www-form-urlencoded": schema
              }
            
          for m in route.httpMethod:
            result["paths"][route.path][m.toLower()] = pathData
  )
