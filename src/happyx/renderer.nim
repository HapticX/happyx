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


proc buildHtmlProcedure*(root: NimNode, body: NimNode): NimNode {.compileTime.} =
  ## Builds HTML
  result = newCall("initTag", newStrLitNode($root))

  for statement in body:
    echo statement.kind

    if statement.kind == nnkCall:
      let
        tagName = newStrLitNode($statement[0])
        statementList = statement[^1]
      var attrs = newNimNode(nnkTableConstr)
      # tag(attr="value"):
      #   ...
      if statement.len-2 > 0 and statementList.kind == nnkStmtList:
        for attr in statement[1 .. statement.len-2]:
          attrs.add(newColonExpr(newStrLitNode($attr[0]), attr[1]))
        result.add(newCall("newStringTable", attrs), buildHtmlProcedure(tagName, statementList))
      # tag(attr="value")
      elif statementList.kind != nnkStmtList:
        for attr in statement[1 .. statement.len-1]:
          attrs.add(newColonExpr(newStrLitNode($attr[0]), attr[1]))
        if attrs.len > 0:
          result.add(newCall("initTag", tagName, newCall("newStringTable", attrs)))
        else:
          result.add(newCall("initTag", tagName))
      # tag:
      #   ...
      else:
        result.add(buildHtmlProcedure(tagName, statementList))
    
    elif statement.kind == nnkStrLit:
      # "Raw text"
      result.add(newCall("initTag", statement, newLit(true)))
    
    elif statement.kind == nnkIdent:
      # tag
      result.add(newCall("tag", newStrLitNode($statement)))
    
    # if a:
    #   ...
    # else:
    #   ...
    elif statement.kind == nnkIfStmt:
      var ifExpr = newNimNode(nnkIfExpr)
      for branch in statement:
        if branch.kind == nnkElifBranch:
          let r = buildHtmlProcedure(ident("div"), branch[1])
          echo treeRepr r
          let elifExpr = newNimNode(nnkElifExpr).add(branch[0])
          for i in r[2..^1]:
            elifExpr.add(i)
          ifExpr.add(elifExpr)
        else:
          let r = buildHtmlProcedure(ident("div"), branch[0])
          let elseExpr = newNimNode(nnkElseExpr)
          for i in r[2..^1]:
            elseExpr.add(i)
          ifExpr.add(elseExpr)
      if ifExpr.len == 1:
        ifExpr.add(newNimNode(nnkElseExpr).add(
          newCall("tag", newStrLitNode("div"))
        ))
      result.add(ifExpr)


macro buildHtml*(root, html: untyped): untyped =
  ## Builds HTML
  ## 
  ## Args:
  ## - `root`: root element. It's can be `tag`, tag or tTag
  ## - `html`: YAML-like structure.
  ## 
  runnableExamples:
    var state = true
    var html = buildHtml(`div`):
      h1(class="title"):
        "Title"
      input(`type`="password")
      button:
        "click!"
      if state:
        "state is true!"
      else:
        "state is false"
  result = buildHtmlProcedure(root, html)
  echo treeRepr result
