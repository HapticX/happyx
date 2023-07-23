## # Style 🎴
## 
## > Provides powerful CSS builder 🍍
## 
## ## Usage
## 
## ### Tags
## 
## In CSS tags is
## 
## .. code-block::css
##    div {
##      background: url("image.png")
##    }
## 
## .. code-block::nim
##    buildStyle:
##      tag tDiv:
##        background: url("image.png")
## 
## ### Classes
## 
## In CSS classes is
## 
## .. code-block::css
##    .myClass {
##      background: url("image.png")
##    }
## 
## .. code-block::nim
##    buildStyle:
##      class myClass:
##        background: url("image.png")
## 
## ### IDs
## 
## In CSS IDs is
## 
## .. code-block::css
##    #myElement {
##      background: url("image.png")
##    }
## 
## .. code-block::nim
##    buildStyle:
##      id myElement:
##        background: url("image.png")
## 
## ### Media, Supports, Etc.
## 
## In CSS it maybe:
## 
## .. code-block::css
##    @supports (display: flex) {
##      @media screen and (min-width: 900px) {
##        article {
##          display: flex;
##        }
##      }
##    }
## 
## .. code-block::nim
##    buildStyle:
##      @supports (display: flex):
##        @media screen and (min-width: 900.px):
##          tag article:
##            display: flex
## 
import
  # stdlib
  strutils,
  strformat,
  macros,
  # deps
  regex,
  # HappyX
  ../core/[exceptions],
  ../private/[macro_utils]


const nnkNumbers* = nnkIntLit..nnkFloat128Lit


proc buildStyleProc(body: NimNode, css: var string, level: int = 0, pretty: bool = true) {. compileTime .} =
  let
    newLine = if pretty: "\n" else: ""
    levelStr = repeat(' ', level)
  for statement in body:
    # @import ...
    if statement.kind == nnkImportStmt:
      css &= levelStr & fmt"@import {statement[0].toStrLit};" & newLine
    # classes
    elif statement.kind in nnkCallKinds and statement[0].kind == nnkIdent and $statement[0] == "class":
      if statement.len != 3 and statement[^1].kind != nnkStmtList:
        throwDefect(
          HpxBuildStyleDefect,
          fmt"Invalid buildStyle syntax! classes should have name and body! ",
          lineInfoObj(statement)
        )
      css &= levelStr & "." & $statement[1].toStrLit & " {" & newLine
      statement[^1].buildStyleProc(css, level + 2, pretty)
      css &= levelStr & "}" & newLine
    # ids
    elif statement.kind in nnkCallKinds and statement[0].kind == nnkIdent and $statement[0] == "id":
      if statement.len != 3 and statement[^1].kind != nnkStmtList:
        throwDefect(
          HpxBuildStyleDefect,
          fmt"Invalid buildStyle syntax! IDs should have name and body! ",
          lineInfoObj(statement)
        )
      css &= levelStr & "#" & $statement[1] & " {" & newLine
      statement[^1].buildStyleProc(css, level + 2, pretty)
      css &= levelStr & "}" & newLine
    # tags
    elif statement.kind in nnkCallKinds and statement[0].kind == nnkIdent and $statement[0] == "tag":
      if statement.len != 3 and statement[^1].kind != nnkStmtList:
        throwDefect(
          HpxBuildStyleDefect,
          fmt"Invalid buildStyle syntax! tags should have name and body! ",
          lineInfoObj(statement)
        )
      css &= levelStr & getTagName($statement[1]) & " {" & newLine
      statement[^1].buildStyleProc(css, level + 2, pretty)
      css &= levelStr & "}" & newLine
    # at-rules
    # as example https://developer.mozilla.org/en-US/docs/Web/CSS/@charset
    elif statement.kind in nnkCallKinds and statement[0].kind == nnkPrefix and $statement[0][0] == "@":
      if statement.len < 3 and $statement[0][1] != "charset":
        throwDefect(
          HpxBuildStyleDefect,
          fmt"Invalid buildStyle syntax! At-rule should have name and body! ",
          lineInfoObj(statement)
        )
      if statement[0][1].kind != nnkIdent:
        throwDefect(
          HpxBuildStyleDefect,
          "Invalid buildStyle syntax! At-rule should have ident (@AtRuleName).\nAs example:\n@keyframes\n",
          lineInfoObj(statement[0][1])
        )
      let atRule = $statement[0][1]
      case atRule.toLower()
      of "charset":
        css &= levelStr & "@charset " & $statement[^1].toStrLit & newLine
      of "keyframes":
        css &= levelStr & "@keyframes " & $statement[1] & " {" & newLine
        statement[^1].buildStyleProc(css, level + 2, pretty)
        css &= levelStr & "}" & newLine
      of "media", "supports", "container":
        var args: seq[string] = @[]
        for i in 1..<statement.len-1:
          args.add($statement[i].toStrLit)
        css &= levelStr & "@" & atRule & " " & args.join(", ") & " {" & newLine
        statement[^1].buildStyleProc(css, level + 2, pretty)
        css &= levelStr & "}" & newLine
    # keyframes
    elif statement.kind in nnkCallKinds and statement[0].kind in nnkNumbers:
      if statement.len != 2 and statement[^1].kind != nnkStmtList:
        throwDefect(
          HpxBuildStyleDefect,
          fmt"Invalid buildStyle syntax! IDs should have name and body! ",
          lineInfoObj(statement)
        )
      let percent = int(parseFloat($statement[0].toStrLit))
      css &= levelStr & $percent & "% {" & newLine
      statement[^1].buildStyleProc(css, level + 2, pretty)
      css &= levelStr & "}" & newLine
    # pseudo classes
    elif statement.kind == nnkInfix and $statement[0] == "@":
      let tagName =
        if statement[1].kind == nnkIdent:
          getTagName($statement[1])
        else:
          $statement[1].toStrLit
      css &= levelStr & tagName & ":" & $statement[2].toStrLit & " {" & newLine
      statement[^1].buildStyleProc(css, level + 2, pretty)
      css &= levelStr & "}" & newLine
    # complex property
    elif statement.kind == nnkInfix and statement.len == 4 and statement[^1].kind == nnkStmtList:
      if statement[3].len != 1:
        throwDefect(
          HpxBuildStyleDefect,
          fmt"Invalid buildStyle syntax! Property should have only one value ",
          lineInfoObj(statement[1])
        )
      var key = copy(statement)
      key.del(3)
      css &= levelStr & $key.toStrLit & ": " & ($statement[3].toStrLit).replace("\n", "") & ";" & newLine
    # simple property
    elif statement.kind in nnkCallKinds and statement.len == 2 and statement[0].kind == nnkIdent and statement[^1].kind == nnkStmtList:
      if statement[1].len != 1:
        throwDefect(
          HpxBuildStyleDefect,
          fmt"Invalid buildStyle syntax! Property should have only one value ",
          lineInfoObj(statement[1])
        )
      if statement[0].kind != nnkIdent:
        throwDefect(
          HpxBuildStyleDefect,
          fmt"Invalid buildStyle syntax! Property name should be ident! ",
          lineInfoObj(statement[1])
        )
      css &= levelStr & $statement[0] & ": " & ($statement[1].toStrLit).replace("\n", "") & ";" & newLine


macro buildStyle*(body: untyped): untyped =
  ## Builds CSS in pure Nim
  ## 
  ## Support:
  ## - pseudo classes;
  ## - simple and complex properties;
  ## - @keyframes;
  ## - @media queries;
  ## - @charset, @supports, @container;
  ## - nim variables in double curly brackets
  ## 
  runnableExamples:
    import strformat
    var
      nimVariable = "#fefefe"
      otherNimVariable = "rgb(100, 255, 100)"
      myCss = buildStyle:
        # Translates into @import url(...)
        import url("path/to/font")
        # Translates into .myClass
        class myClass:
          color: {{nimVariable}}
          background-color: {{otherNimVariable}}
        # Translates into #myId
        id myId:
          color: red
        # Translates into body
        tag body:
          color: white
          background: rgb(33, 33, 33)
        # Translates into @keyframes
        @keyframes animation:
          0:  # translates into 0%
            opacity: 0
            tranform: translateX(-150.px)
          100:  # translates into 100%
            opacity: 1
            transform: translateX(0.px)
        # Translates into @media ...
        @media screen and (min-width: 900.px):
          tag article:
            padding: 1.rem 3.rem
        # Translates into button:hover
        button@hover:
          color: red

  var css = ""
  body.buildStyleProc(css)
  # formatting
  css = css.replace(re"\{\{([^\}]+)\}\}", "<$1>")
  # UOMs
  css = css.replace(re"\.(px|rem|em)\b", "$1")
  # properties
  css = css.replace(re"\s*\-\s*([a-zA-Z][a-zA-Z0-9_]*)", "-$1")
  newCall("fmt", newStrLitNode(css), newLit('<'), newLit('>'))
