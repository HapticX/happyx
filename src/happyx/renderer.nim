## The renderer.nim module in the HappyX web-async framework provides
## a single-page application (SPA) renderer with reactivity features.
## It likely contains functions or classes that allow developers to
## dynamically update the content of a web page without reloading the entire page.

import
  macros,
  logging,
  htmlgen,
  strutils,
  strtabs,
  strformat,
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
      if statement.len-2 > 0:
        var attrs = newNimNode(nnkTableConstr).add()
        for attr in statement[1 .. statement.len-2]:
          attrs.add(newColonExpr(newStrLitNode($attr[0]), attr[1]))
        result.add(newCall("newStringTable", attrs))
      result.add(buildHtmlProcedure(tagName, statementList))
    
    elif statement.kind == nnkStrLit:
      result.add(newCall("initTag", statement, newLit(true)))
    
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
  echo treeRepr root
  result = buildHtmlProcedure(root, html)
  echo treeRepr result
