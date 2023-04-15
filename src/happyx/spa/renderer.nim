## # Renderer
## 
## Provides a single-page application (SPA) renderer with reactivity features.
## It likely contains functions or classes that allow developers to
## dynamically update the content of a web page without reloading the entire page.

import
  macros,
  logging,
  htmlgen,
  strtabs,
  sugar,
  strutils,
  strformat,
  tables,
  regex,
  ./tag,
  ../private/cmpltime

when defined(js):
  import
    dom,
    jsconsole
  export
    dom,
    jsconsole

export
  strformat,
  logging,
  htmlgen,
  strtabs,
  strutils,
  tables,
  regex,
  sugar,
  tag


type
  AppEventHandler* = proc()
  App* = object
    appId*: string


var eventHandlers*: seq[AppEventHandler] = @[]


when defined(js):
  {.emit: "function callEventHandler(idx) {".}
  var idx: int
  {.emit: "`idx` = idx;" .}
  eventHandlers[idx]()
  {.emit: "}" .}


func newApp*(appId: string = "app"): App =
  ## Creates a new Singla Page Application
  result = App(appId: appId)


template start*(app: App) =
  ## Starts single page application
  document.addEventListener("DOMContentLoaded", onDOMContentLoaded)
  window.addEventListener("popstate", onDOMContentLoaded)


proc replaceIter*(
    root: NimNode,
    search: proc(x: NimNode): bool,
    replace: proc(x: NimNode): NimNode
): bool =
  result = false
  for i in 0..root.len-1:
    result = root[i].replaceIter(search, replace)
    if search(root[i]):
      root[i] = replace(root[i])
      result = true


proc getTagName*(name: string): string {.compileTime.} =
  ## Checks tag name at compile time
  ## 
  ## tagDiv, tDiv, hDiv -> div
  if re"^tag[A-Z]" in name:
    name[3..^1].toLower()
  elif re"^[ht][A-Z]" in name:
    name[1..^1].toLower()
  else:
    name


proc attribute(attr: NimNode): NimNode {. compileTime .} =
  newColonExpr(
    newStrLitNode($attr[0]),
    if attr[1].kind in [nnkStrLit, nnkTripleStrLit]:
      newCall("fmt", attr[1])
    else:
      attr[1]
  )


proc addAttribute(node, key, value: NimNode) {. compileTime .} =
  if node.len == 2:
    node.add(newCall("newStringTable", newNimNode(nnkTableConstr).add(
      newColonExpr(newStrLitNode($key), value)
    )))
  elif node[2][1].kind == nnkTableConstr:
    node[2][1].add(newColonExpr(newStrLitNode($key), value))
  else:
    node.insert(2, newCall("newStringTable", newNimNode(nnkTableConstr).add(
      newColonExpr(newStrLitNode($key), value)
    )))


proc buildHtmlProcedure*(root, body: NimNode, uniqueId: ptr int): NimNode {.compileTime.} =
  ## Builds HTML
  let elementName = newStrLitNode(getTagName($root))
  result = newCall("initTag", elementName)

  for statement in body:
    if statement.kind == nnkCall:
      let
        tagName = newStrLitNode(getTagName($statement[0]))
        statementList = statement[^1]
      var attrs = newNimNode(nnkTableConstr)
      # tag(attr="value"):
      #   ...
      if statement.len-2 > 0 and statementList.kind == nnkStmtList:
        for attr in statement[1 .. statement.len-2]:
          attrs.add(attribute(attr))
        var builded = buildHtmlProcedure(tagName, statementList, uniqueId)
        builded.insert(2, newCall("newStringTable", attrs))
        result.add(builded)
      # tag(attr="value")
      elif statementList.kind != nnkStmtList:
        for attr in statement[1 .. statement.len-1]:
          attrs.add(attribute(attr))
        if attrs.len > 0:
          result.add(newCall("initTag", tagName, newCall("newStringTable", attrs)))
        else:
          result.add(newCall("initTag", tagName))
      # tag:
      #   ...
      else:
        result.add(buildHtmlProcedure(tagName, statementList, uniqueId))
    
    elif statement.kind in [nnkStrLit, nnkTripleStrLit]:
      # "Raw text"
      result.add(newCall("initTag", newCall("fmt", statement), newLit(true)))
    
    elif statement.kind == nnkAsgn:
      # Attributes
      result.addAttribute(statement[0], statement[1])
    
    # Events handling
    elif statement.kind == nnkPrefix and $statement[0] == "@":
      let
        event = $statement[1]
        uId = uniqueId[]
        procedure = newNimNode(nnkLambda).add(
          newEmptyNode(), newEmptyNode(), newEmptyNode(),
          newNimNode(nnkFormalParams).add(
            newEmptyNode()
          ),
          newEmptyNode(), newEmptyNode(),
          newStmtList()
        )
      inc uniqueId[]
      procedure.body = statement[2]
      result.addAttribute(
        newStrLitNode(fmt"on{event}"),
        newStrLitNode(fmt"callEventHandler({uId})")
      )
      result.add(newStmtList(
        newCall("add", ident("eventHandlers"), procedure),
        newNilLit()
      ))
    
    elif statement.kind == nnkIdent:
      # tag
      result.add(newCall("tag", newStrLitNode(getTagName($statement))))
    
    elif statement.kind == nnkAccQuoted:
      # `tag`
      result.add(newCall("tag", newStrLitNode(getTagName($statement[0]))))
    
    elif statement.kind == nnkCurly and statement.len == 1:
      # variables
      result.add(newCall("initTag", newCall("$", statement[0]), newLit(true)))
    
    # if a:
    #   ...
    # else:
    #   ...
    elif statement.kind == nnkIfStmt:
      var ifExpr = newNimNode(nnkIfExpr)
      for branch in statement:
        if branch.kind == nnkElifBranch:
          ifExpr.add(newNimNode(nnkElifExpr).add(
            branch[0], buildHtmlProcedure(ident("div"), branch[1], uniqueId).add(newLit(true))
          ))
        else:
          ifExpr.add(newNimNode(nnkElseExpr).add(
            buildHtmlProcedure(ident("div"), branch[0], uniqueId).add(newLit(true))
          ))
      if ifExpr.len == 1:
        ifExpr.add(newNimNode(nnkElseExpr).add(
          newCall("initTag", newStrLitNode("div"), newCall("@", newNimNode(nnkBracket)), newLit(true))
        ))
      result.add(ifExpr)
    
    # for ... in ...:
    #   ...
    elif statement.kind == nnkForStmt:
      let
        arguments = collect(newSeq):
          for i in statement[0..statement.len-3]:
            $i
      # nnkCall
      var replaced = statement[^1].replaceIter(
        (x) => x.kind == nnkCall and $x[0] in arguments,
        proc(x: NimNode): NimNode =
          let stmtList = x[^1]
          var
            builded: NimNode
            attrs = newNimNode(nnkTableConstr)
          if stmtList.kind == nnkStmtList:
            builded = buildHtmlProcedure(x[0], x[^1], uniqueId)
            # tag(attr="value"):
            #   ...
            for attr in x[1 .. x.len-2]:
              attrs.add(attribute(attr))
          else:
            builded = buildHtmlProcedure(x[0], newStmtList(), uniqueId)
            # tag(attr="value"):
            #   ...
            for attr in x[1 .. x.len-1]:
              attrs.add(attribute(attr))
          builded.insert(2, newCall("newStringTable", attrs))
          newNimNode(nnkIfExpr).add(
            newNimNode(nnkElifExpr).add(
              newCall("is", newCall("typeof", x[0]), ident("string")),
              builded
            )
          )
      )
      if not replaced:
        # nnkIdent
        replaced = statement[^1].replaceIter(
          (x) => x.kind == nnkIdent and $x in arguments,
          (x) => newNimNode(nnkIfExpr).add(
            newNimNode(nnkElifExpr).add(
              newCall("is", newCall("typeof", x), ident("string")),
              newCall("initTag", x)
            )
          )
        )
      # as varibale with {}
      discard statement[^1].replaceIter(
        (x) => x.kind == nnkCurly and x.len == 1 and x[0].kind == nnkIdent and $x[0] in arguments,
        (x) => newCall("initTag", newCall("$", x[0]), newLit(true))
      )
      result.add(
        newCall(
          "initTag",
          newStrLitNode("div"),
          newCall(
            "collect",
            ident("newSeq"),
            newNimNode(nnkStmtList).add(statement)
          ),
          newLit(true)
        )
      )
  
  # varargs -> seq
  if result.len > 2:
    if result[2].kind == nnkCall and $result[2][0] == "newStringTable":
      var
        tagRefs = result[3..result.len-1]
        arr = newNimNode(nnkBracket)
      result.del(3, result.len - 3)
      for tag in tagRefs:
        arr.add(tag)
      result.add(newCall("@", arr))
    else:
      var
        tagRefs = result[2..result.len-1]
        arr = newNimNode(nnkBracket)
      result.del(2, result.len - 2)
      for tag in tagRefs:
        arr.add(tag)
      result.add(newCall("@", arr))


macro buildHtml*(root: untyped, html: untyped): untyped =
  ## `buildHtml` macro provides building HTML tags with YAML-like syntax.
  ## 
  ## Args:
  ## - `root`: root element. It's can be `tag`, tag or tTag
  ## - `html`: YAML-like structure.
  ## 
  ## Syntax support:
  ##   - attributes via exprEqExpr
  ##   
  ##     .. code-block:: nim
  ##        echo buildHtml(`div`):
  ##          h1(class="myClass", align="center")
  ##          input(`type`="password", align="center")
  ##   
  ##   - nested tags
  ##   
  ##     .. code-block:: nim
  ##        echo buildHtml(`div`):
  ##          tag:
  ##            tag1:
  ##              tag2:
  ##            tag1withattrs(attr="value")
  ##   
  ##   - if-elif-else expressions
  ## 
  ##     .. code-block:: nim
  ##        var state = true
  ##        echo buildHtml(`div`):
  ##          if state:
  ##            "True!"
  ##          else:
  ##            "False("
  ##   
  ##   - for statements
  ## 
  ##     .. code-block:: nim
  ##        var state = @["h1", "h2", "input"]
  ##        echo buildHtml(`div`):
  ##          for i in state:
  ##            i
  ## 
  var uniqueId = 0
  buildHtmlProcedure(root, html, addr uniqueId)


macro routes*(app: App, body: untyped): untyped =
  ## Provides JS router for Single page application
  let
    iPath = ident("path")
    iHtml = ident("html")
    iRouter = ident("router")
    router = newProc(iRouter)
    navigate = newProc(
      ident("navigate"),
      [newEmptyNode(), newIdentDefs(ident("path"), ident("string"))]
    )
    onDOMContentLoaded = newProc(
      ident("onDOMContentLoaded"),
      [newEmptyNode(), newIdentDefs(ident("ev"), ident("Event"))]
    )
    ifStmt = newNimNode(nnkIfStmt)

  # Navigate proc
  navigate.body = newStmtList(
    newCall(
      "pushState",
      newDotExpr(ident("window"), ident("history")),
      newLit(""),
      newLit(""),
      iPath
    ),
    newCall(iRouter)
  )

  # On DOM Content Loaded
  onDOMContentLoaded.body = newStmtList(newCall(iRouter))
  router.body = newStmtList()

  # Router
  router.body.add(
    newLetStmt(
      ident("elem"),
      newCall("getElementById", ident("document"), newDotExpr(ident("app"), ident("appId")))
    ),
    newLetStmt(
      ident("path"),
      newCall(
        "strip",
        newCall("$", newDotExpr(newDotExpr(ident("window"), ident("location")), ident("hash"))),
        newLit(true),
        newLit(false),
        newNimNode(nnkCurly).add(newLit('#'))
      )
    ),
    newNimNode(nnkVarSection).add(newIdentDefs(
      iHtml, ident("TagRef"), newNilLit()
    ))
  )

  for statement in body:
    if statement.kind in [nnkCommand, nnkCall]:
      if statement.len == 2 and statement[0].kind == nnkStrLit:
        let exported = exportRouteArgs(
          iPath,
          statement[0],
          statement[1]
        )
        # Route contains params
        if exported.len > 0:
          exported[^1][^1] = newAssignment(iHtml, exported[^1][^1])
          ifStmt.add(exported)
        # Route doesn't contains any params
        else:
          ifStmt.add(newNimNode(nnkElifBranch).add(
            newCall("==", iPath, statement[0]),
            newAssignment(iHtml, statement[1])
          ))
      elif statement[1].kind == nnkStmtList and statement[0].kind == nnkIdent:
        case $statement[0]
        of "notfound":
          router.body.add(
            newAssignment(iHtml, statement[1])
          )
  
  if ifStmt.len > 0:
    router.body.add(ifStmt)
  
  router.body.add(
    newNimNode(nnkIfStmt).add(newNimNode(nnkElifBranch).add(
      newCall("not", newCall("isNil", iHtml)),
      newStmtList(
        newAssignment(
          newDotExpr(ident("elem"), ident("innerHTML")),
          newCall("$", iHtml)
        )
      )
    ))
  )

  newStmtList(
    router,
    onDOMContentLoaded,
    navigate,
  )
