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
  ./tag

export
  logging,
  htmlgen,
  strtabs,
  tag


type
  Renderer* = object
    appId*: string


func newRenderer*(appId: string): Renderer =
  ## Creates a new renderer
  result = Renderer(
    appId: appId
  )


proc buildHtmlProcedure*(root, body: NimNode): NimNode {.compileTime.} =
  ## Builds HTML
  result = newCall("initTag", newStrLitNode($root))

  for statement in body:
    echo statement.kind

    if statement.kind == nnkCall:
      let
        tagName = newStrLitNode($statement[0])
        statementList = statement[^1]
      var attrs = newNimNode(nnkTableConstr)
      if statement.len-2 > 0 and statementList.kind == nnkStmtList:
        for attr in statement[1 .. statement.len-2]:
          attrs.add(newColonExpr(newStrLitNode($attr[0]), attr[1]))
        result.add(newCall("newStringTable", attrs), buildHtmlProcedure(tagName, statementList))
      elif statementList.kind != nnkStmtList:
        for attr in statement[1 .. statement.len-1]:
          attrs.add(newColonExpr(newStrLitNode($attr[0]), attr[1]))
        if attrs.len > 0:
          result.add(newCall("initTag", tagName, newCall("newStringTable", attrs)))
        else:
          result.add(newCall("initTag", tagName))
      else:
        result.add(buildHtmlProcedure(tagName, statementList))
    
    elif statement.kind == nnkStrLit:
      result.add(newCall("initTag", statement, newLit(true)))
    
    elif statement.kind == nnkIdent:
      result.add(newCall("tag", newStrLitNode($statement)))
    
    elif statement.kind == nnkIfStmt:
      var ifExpr = newNimNode(nnkIfExpr)
      for branch in statement:
        if branch.kind == nnkElifBranch:
          ifExpr.add(newNimNode(nnkElifExpr).add(
            branch[0], buildHtmlProcedure(newStrLitNode("div"), branch[1])
          ))
        else:
          ifExpr.add(newNimNode(nnkElseExpr).add(
            buildHtmlProcedure(newStrLitNode("div"), branch[0])
          ))
      result.add(ifExpr)


macro buildHtml*(root, html: untyped): untyped =
  ## Builds HTML
  runnableExamples:
    var html = buildHtml(`div`):
      h1(class="title"):
        "Title"
      input(`type`="password")
      button:
        "click!"
  result = buildHtmlProcedure(root, html)
  echo treeRepr result
