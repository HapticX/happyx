import
  std/macros,
  std/macrocache,
  std/strutils,
  ../../spa/renderer,
  ./utils,
  ../../private/macro_utils


const liveViewsCache* = CacheSeq"HappyXLiveViews"

const
  useWss* {.booldefine.}: bool = false
  liveviewWsHost* {.strdefine.}: string = ""


macro liveview*(body: untyped): untyped =
  for statement in body:
    if statement.kind in nnkCallKinds and statement[0].kind in {nnkStrLit, nnkTripleStrLit} and statement[1].kind == nnkStmtList:
      liveViewsCache.add(newStmtList(statement[0], statement[1]))


proc handleLiveViews*(body: NimNode) =
  for liveView in liveViewsCache:
    let
      path = liveView[0]
      statement = liveView[1]
    var head = newCall("head", newStmtList(newCall("tTitle", newStmtList(newLit"HappyX Application"))))
    for i in 0..<statement.len:
      if statement[i].kind == nnkCall and ($statement[i][0]).toLower() == "head":
        head = statement[i].copy()
        statement.del(i)
        break
    let
      connection = newCall(
        "&",
        newCall(
          "&",
          if liveviewWsHost == "":
            newCall(
              "&",
              newCall(
                "&",
                newCall(
                  "&",
                  if useWss:
                    newLit("var _sc=new WebSocket(\"wss://")
                  else:
                    newLit("var _sc=new WebSocket(\"ws://"),
                  newDotExpr(ident"server", ident"address"),
                ),
                newLit":",
              ),
              newCall("$", newDotExpr(ident"server", ident"port"))
            )
          elif useWss:
            newLit("var _sc=new WebSocket(\"wss://" & liveviewWsHost)
          else:
            newLit("var _sc=new WebSocket(\"ws://" & liveviewWsHost),
          path
        ),
        newLit("\");")
      )
      script = liveViewScript()
    script[1][0] = newNimNode(nnkCurly).add(
      newCall("&", connection, newLit(
        ($script[1][0]).replace("\n", "")
      ))
    )
    let
      getMethod = pragmaBlock([ident"gcsafe"], newStmtList(
        newNimNode(nnkIfStmt).add(newNimNode(nnkElifBranch).add(
          newCall("not", newCall("hasKey", ident"liveviewRoutes", path)),
          newNimNode(nnkAsgn).add(
            newNimNode(nnkBracketExpr).add(ident"liveviewRoutes", path),
            newLambda(newStmtList(
              newCall("buildHtml", newStmtList(
                head,
                newCall("body", newStmtList(
                  newCall("tDiv", newNimNode(nnkExprEqExpr).add(ident"id", newLit"app"), statement),
                  newCall("tDiv", newNimNode(nnkExprEqExpr).add(ident"id", newLit"scripts"))
                ))
              ))
            ), @[
              ident"TagRef",
              newIdentDefs(ident"query", ident"StringTableRef", newEmptyNode()),
              newIdentDefs(ident"queryArr", newNimNode(nnkBracketExpr).add(ident"TableRef", ident"string", newNimNode(nnkBracketExpr).add(ident"seq", ident"string")), newEmptyNode()),
              newIdentDefs(ident"reqMethod", ident"HttpMethod", newEmptyNode()),
              newIdentDefs(ident"inCookies", ident"StringTableRef", newEmptyNode()),
              newIdentDefs(ident"headers", ident"HttpHeaders", newEmptyNode()),
              newIdentDefs(ident"component", ident"BaseComponent", newEmptyNode()),
            ])
          ),
        )),
        newLetStmt(ident"_html", newCall(
          newNimNode(nnkBracketExpr).add(ident"liveviewRoutes", path),
          ident"query", ident"queryArr", ident"reqMethod", ident"inCookies", ident"headers", newNilLit()
        )),
        newCall("add", newNimNode(nnkBracketExpr).add(ident"_html", newLit(1)), newCall("buildHtml", newStmtList(script))),
        newNimNode(nnkReturnStmt).add(ident"_html"),
      ))
      wsMethod = quote do:
        ws `path`:
          let parsed = parseJson(wsData)
          {.gcsafe.}:
            case parsed["a"].getInt
            of 2:
              let comp = components[parsed["cid"].getStr]
              componentEventHandlers[parsed["idx"].getInt](comp, parsed["ev"])
              if componentsResult.hasKey(comp.uniqCompId):
                await wsClient.send($componentsResult[comp.uniqCompId])
                componentsResult.del(comp.uniqCompId)
            of 1:
              eventHandlers[parsed["idx"].getInt](parsed["ev"])
              if requestResult.hasKey(hostname):
                await wsClient.send($requestResult[hostname])
                requestResult.del(hostname)
            else:
              discard
    body.add(wsMethod)
    body.add(newCall(ident"get", path, getMethod))
