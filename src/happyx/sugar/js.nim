## Provides JS2Nim bridge
## 
## You can write PURE JS in PURE Nim with it ✌
import
  # Stdlib
  strformat,
  strutils,
  macros,
  # Deps
  regex,
  # HappyX
  ../private/exceptions


proc buildJsProc(body: NimNode, src: var string, lvl: int = 0,
                 pretty: bool = true, inClass: bool = false) {. compileTime .} =
  let
    newLine = if pretty: "\n" else: ""
    level = repeat(' ', lvl)
  for statement in body:
    # function funcName(args) { ... }
    if statement.kind == nnkCommand and statement[0] == ident("function") and statement[1].kind == nnkCall:
      # check syntax
      for i in statement[1]:
        if i.kind != nnkIdent:
          throwDefect(
            SyntaxJsDefect,
            "Wrong function declaration! function name and function arguments should be idents! ",
            lineInfoObj(statement[1])
          )
      if statement[^1].kind != nnkStmtList:
        throwDefect(
          SyntaxJsDefect,
          "Wrong function declaration! Function should have body! ",
          lineInfoObj(statement[^1])
        )
      src &= level & "function " & $statement[1].toStrLit & " {" & newLine
      statement[^1].buildJsProc(src, lvl + 2, pretty)
      src &= level & "}" & newLine
    
    # variable declaration
    elif statement.kind == nnkVarSection:
      for i in statement:
        if i[0].kind != nnkIdent:
          throwDefect(
            SyntaxJsDefect,
            "Wrong var declaration! Variable name should be ident! ",
            lineInfoObj(i)
          )
        src &= level & "let " & $i[0].toStrLit & " = " & $i[2].toStrLit & ";" & newLine
    
    # const declaration
    elif statement.kind in [nnkLetSection, nnkConstSection]:
      for i in statement:
        if i[0].kind != nnkIdent:
          throwDefect(
            SyntaxJsDefect,
            "Wrong var declaration! Variable name should be ident! ",
            lineInfoObj(i)
          )
        src &= level & "const " & $i[0].toStrLit & " = " & $i[2].toStrLit & ";" & newLine
    
    # echo to console.log convertion
    elif statement.kind in nnkCallKinds and statement[0] == ident("echo"):
      var args: seq[string] = @[]
      for i in 1..<statement.len:
        args.add($statement[i].toStrLit)
      src &= level & "console.log(" & args.join(", ") & ");" & newLine
    
    # for statement
    elif statement.kind == nnkForStmt:
      let
        arg = statement[0]
        arr = statement[1]
        forStmt = statement[2]
      if arr.kind == nnkInfix:
        if $arr[0] == "..":
          src &= fmt"{level}for (var {arg} = {arr[1].toStrLit}; {arg} < {arr[2].toStrLit}; ++{arg})" & "{" & newLine
          forStmt.buildJsProc(src, lvl + 2, pretty)
          src &= level & "}" & newLine
        elif $arr[0] == "..<":
          src &= fmt"{level}for (var {arg} = {arr[1].toStrLit}; {arg} < {arr[2].toStrLit}-1; ++{arg})" & "{" & newLine
          forStmt.buildJsProc(src, lvl + 2, pretty)
          src &= level & "}" & newLine
      else:
        src &= fmt"{level}{arr.toStrLit}.forEach({arg.toStrLit} => " & "{" & newLine
        forStmt.buildJsProc(src, lvl + 2, pretty)
        src &= level & "});" & newLine
    
    # class statement
    elif statement.kind == nnkCommand and statement[0] == ident("class"):
      if statement[^1].kind != nnkStmtList or statement.len != 3:
        throwDefect(
          SyntaxJsDefect,
          "Wrong buildJs syntax! class should have name and body ",
          lineInfoObj(statement)
        )
      src &= fmt"{level}class {statement[1].toStrLit}" & " {" & newLine
      statement[^1].buildJsProc(src, lvl + 2, pretty, true)
      src &= level & "}" & newLine
    
    # class fields with default values
    elif statement.kind == nnkAsgn and inClass:
      if statement[0].kind == nnkIdent:
        src &= fmt"{level}#{statement[0]} = {statement[1].toStrLit};{newLine}"
      elif statement[0].kind == nnkCommand and statement[0][0] == ident("pub"):
        src &= fmt"{level}{statement[0][1].toStrLit} = {statement[1].toStrLit};{newLine}"
    # class private fields
    elif statement.kind == nnkIdent and inClass:
      src &= fmt"{level}#{statement};{newLine}"
    # class public fields
    elif statement.kind == nnkCommand and statement[0] == ident("pub"):
      src &= fmt"{level}{statement[1].toStrLit};{newLine}"
    
    # class functions
    elif statement.kind == nnkCall and statement[^1].kind == nnkStmtList and inClass:
      var node = copy(statement)
      node.del(node.len-1)
      src &= fmt"{level}{node.toStrLit}" & " {" & newLine
      statement[^1].buildJsProc(src, lvl + 2, pretty)
      src &= level & "}" & newLine
    
    # if statements
    elif statement.kind == nnkIfStmt:
      var idx = 0
      for branch in statement:
        if branch.kind == nnkElifBranch:
          if idx == 0:
            src &= fmt"{level}if ({branch[0].toStrLit})" & " {" & newLine
          else:
            src &= fmt"else if ({branch[0].toStrLit})" & " {" & newLine
          branch[1].buildJsProc(src, lvl + 2, pretty)
          if idx < statement.len-1:
            src &= "} "
          else:
            src &= level & "}" & newLine
        else:
          if idx == 0:
            src &= fmt"{level}else" & " {" & newLine
          else:
            src &= "else {" & newLine
          branch[0].buildJsProc(src, lvl + 2, pretty)
          if idx < statement.len-1:
            src &= "} "
          else:
            src &= level & "}" & newLine
        inc idx
    
    # switch-case statement
    elif statement.kind == nnkCaseStmt:
      src &= level & "switch (" & $statement[0].toStrLit & "){" & newLine
      for i in 1..<statement.len:
        let branch = statement[i]
        # iterate over "of a, b, c ..."
        if branch.kind == nnkOfBranch:
          for ofIdx in 0..<branch.len-1:
            let arg = branch[ofIdx]
            src &= level & "  case " & $arg.toStrLit & ":" & newLine
          branch[1].buildJsProc(src, lvl + 4, pretty)
          src &= level & "    break;" & newLine
        # default
        elif branch.kind == nnkElse:
          src &= level & "  default:" & newLine
          branch[0].buildJsProc(src, lvl + 4, pretty)
          src &= level & "    break;" & newLine
      src &= level & "}" & newLine
    
    # while statement
    elif statement.kind == nnkWhileStmt:
      src &= level & "while (" & $statement[0].toStrLit & ") {" & newLine
      statement[1].buildJsProc(src, lvl + 2, pretty)
      src &= level & "}" & newLine
    
    elif statement.kind == nnkDiscardStmt:
      if statement[0].kind == nnkEmpty:
        discard
      else:
        src &= level & $statement[0].toStrLit & ";" & newLine
    
    # any other statement just converts to string
    else:
      src &= level & $statement.toStrLit & ";" & newLine


macro buildJs*(body: untyped): untyped =
  ## With this macro you can use PURE JavaScript in PURE Nim 👑
  ## 
  ## Available only on `JS` backend ✌
  ## 
  ## Supported syntax statements 👀
  ## - IF-ELIF-ELSE
  ## - CASE-OF
  ## - FOR/WHILE
  ## - variable/constant declaration
  ## 
  ## Also you can use ES6 classes 🥳
  ## 
  ## .. code-block:: nim
  ##    
  ##    class Animal:
  ##      say():
  ##        discard
  ##    
  ##    class Cat extends Animal:
  ##      say():
  ##        echo "Meow"
  ##    
  ##    class Dog extends Animal:
  ##      say():
  ##        echo "Woof!"
  ##    
  ##    var dog = new Dog();
  ##    var cat = new Cat();
  ##    dog.say();
  ##    cat.say();
  ## 
  ## This translates into 💻
  ## 
  ## .. code-block:: js
  ##    class Animal {
  ##      say() {
  ##      }
  ##    }
  ##    class Cat extends Animal {
  ##      say() {
  ##        console.log("Meow");
  ##      }
  ##    }
  ##    class Dog extends Animal {
  ##      say() {
  ##        console.log("Woof!");
  ##      }
  ##    }
  ##    let dog = new Dog();
  ##    let cat = new Cat();
  ##    dog.say();
  ##    cat.say();
  ## 
  var emitSrc = ""
  body.buildJsProc(emitSrc)
  # nim variables
  emitSrc = emitSrc.replace(re"~([a-zA-Z][a-zA-Z0-9_]*)", "`$1`")
  # self -> this
  emitSrc = emitSrc.replace(re"self\.([a-zA-Z][a-zA-Z0-9_]*)", "this.$1")
  newNimNode(nnkPragma).add(newColonExpr(
    ident("emit"),
    newStrLitNode(emitSrc)
  ))
