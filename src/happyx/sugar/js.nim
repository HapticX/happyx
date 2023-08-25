## # JS ✨
## 
## > Provides JS2Nim bridge
## 
## You can write PURE JS in PURE Nim with it ✌
## 
## ## Example
## 
## .. code-block::nim
##    var myNimVariable = 10
##    
##    buildJs:
##      # JavaScript starts here
##      function myJsFunction(a, b, c):
##        # Embedded Nim code
##        nim:
##          echo "Hello, world!"
##        # console.log(myNimVariable)
##        echo ~myNimVariable
##      
##      class Animal:
##        x: int
##        constructor(x):
##          self.x = x
## 
import
  # Stdlib
  strformat,
  strutils,
  macros,
  tables,
  # Deps
  regex,
  # HappyX
  ../core/[exceptions]


var
  enums {. compileTime .} = newTable[string, seq[string]]()
  declaredVariables {. compileTime .} = newSeq[string]()
  nimNodes {. compileTime .} = newSeq[NimNode]()


proc buildJsProc(body: NimNode, src: var string, lvl: int = 0,
                 pretty: bool = true, inClass: bool = false) {. compileTime .} =
  let
    newLine = if pretty: "\n" else: ""
    level = repeat(' ', lvl)
  for statement in body:
    # function funcName(args) { ... }
    if statement.kind == nnkCommand and statement[0] == ident"function" and statement[1].kind == nnkCall:
      # check syntax
      for i in statement[1]:
        if i.kind != nnkIdent:
          throwDefect(
            HpxBuildJsDefect,
            "Wrong function declaration! function name and function arguments should be idents! ",
            lineInfoObj(statement[1])
          )
      if statement[^1].kind != nnkStmtList:
        throwDefect(
          HpxBuildJsDefect,
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
            HpxBuildJsDefect,
            "Wrong var declaration! Variable name should be ident! ",
            lineInfoObj(i)
          )
        src &= level & "let " & $i[0].toStrLit & " = " & $i[2].toStrLit & ";" & newLine
    
    # const declaration
    elif statement.kind in [nnkLetSection, nnkConstSection]:
      for i in statement:
        if i[0].kind != nnkIdent:
          throwDefect(
            HpxBuildJsDefect,
            "Wrong var declaration! Variable name should be ident! ",
            lineInfoObj(i)
          )
        src &= level & "const " & $i[0].toStrLit & " = " & $i[2].toStrLit & ";" & newLine
    
    # nim code
    elif statement.kind == nnkCall and statement[0] == ident"nim" and statement.len == 2 and statement[1].kind == nnkStmtList:
      src &= level & "![#=#]!" & newLine
      nimNodes.add(statement[1])
    
    # echo to console.log convertion
    elif statement.kind in nnkCallKinds and statement[0] == ident"echo":
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
          src &= fmt"{level}for (var {arg} = {arr[1].toStrLit}; {arg} <= {arr[2].toStrLit}; ++{arg})" & "{" & newLine
          forStmt.buildJsProc(src, lvl + 2, pretty)
          src &= level & "}" & newLine
        elif $arr[0] == "..<":
          src &= fmt"{level}for (var {arg} = {arr[1].toStrLit}; {arg} < {arr[2].toStrLit}; ++{arg})" & "{" & newLine
          forStmt.buildJsProc(src, lvl + 2, pretty)
          src &= level & "}" & newLine
      else:
        src &= fmt"{level}{arr.toStrLit}.forEach({arg.toStrLit} => " & "{" & newLine
        forStmt.buildJsProc(src, lvl + 2, pretty)
        src &= level & "});" & newLine
    
    # class statement
    elif statement.kind == nnkCommand and statement[0] == ident"class":
      if statement[^1].kind != nnkStmtList or statement.len != 3:
        throwDefect(
          HpxBuildJsDefect,
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
      elif statement[0].kind == nnkCommand and statement[0][0] == ident"pub":
        src &= fmt"{level}{statement[0][1].toStrLit} = {statement[1].toStrLit};{newLine}"
    # class private fields
    elif statement.kind == nnkIdent and inClass:
      src &= fmt"{level}#{statement};{newLine}"
    # class public fields
    elif statement.kind == nnkCommand and statement[0] == ident"pub":
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
      var
        enumType = ""
        enumCases: seq[string] = @[]
      for i in 1..<statement.len:
        let branch = statement[i]
        # iterate over "of a, b, c ..."
        if branch.kind == nnkOfBranch:
          for ofIdx in 0..<branch.len-1:
            let arg = branch[ofIdx]
            # Detect enum type
            if enumType == "" and arg.kind == nnkDotExpr:
              let k = arg[0]
              if enums.hasKey($k.toStrLit):
                enumType = $k.toStrLit
            # Add val in enumCases if availbale
            if enumType != "":
              enumCases.add($arg[1].toStrLit)
            # Build case statement
            src &= level & "  case " & $arg.toStrLit & ":" & newLine
          branch[1].buildJsProc(src, lvl + 4, pretty)
          src &= level & "    break;" & newLine
        # default
        elif branch.kind == nnkElse:
          # Detect if enumType is detected
          if enumType != "":
            enumCases = enums[enumType]
          src &= level & "  default:" & newLine
          branch[0].buildJsProc(src, lvl + 4, pretty)
          src &= level & "    break;" & newLine
      # Throw error if not all enum
      if enumType != "" and enums[enumType] != enumCases:
        throwDefect(
          HpxBuildJsDefect,
          "Not all enum values are handled in a case-of ",
          lineInfoObj(statement)
        )
      src &= level & "}" & newLine
    
    # while statement
    elif statement.kind == nnkWhileStmt:
      src &= level & "while (" & $statement[0].toStrLit & ") {" & newLine
      statement[1].buildJsProc(src, lvl + 2, pretty)
      src &= level & "}" & newLine
    
    # discard statement
    elif statement.kind == nnkDiscardStmt:
      if statement[0].kind == nnkEmpty:
        discard
      else:
        src &= level & $statement[0].toStrLit & ";" & newLine
    
    # block statement
    elif statement.kind == nnkBlockStmt and statement[0].kind == nnkIdent:
      src &= level & $statement[0] & ":" & newLine
      statement[^1].buildJsProc(src, lvl, pretty)
    
    # Type section
    elif statement.kind == nnkTypeSection:
      for typeDef in statement:
        # Enumerate declaration
        if typeDef[^1].kind == nnkEnumTy and typeDef[0].kind == nnkIdent:
          # Enum value index
          var index = 0
          # Enum name
          let name = $typeDef[0]
          enums[name] = @[]
          # Build enum object
          src &= level & "const " & name & " = {" & newLine
          for field in typeDef[^1]:
            if field.kind == nnkIdent:
              enums[name].add($field)
              src &= level & "  " & $field & ": " & $index & "," & newLine
              inc index
            elif field.kind == nnkEnumFieldDef and field[0].kind == nnkIdent:
              src &= level & "  " & $field[0] & ": " & $field[1].toStrLit & "," & newLine
          src &= level & "}" & newLine
        elif typeDef[^1].kind == nnkObjectTy and typeDef[0].kind == nnkIdent:
          # Object name
          let name = $typeDef[0]
          # Fields
          let recList = typeDef[^1][^1]
          # Build enum object
          src &= level & "class " & name & " {" & newLine
          # Iterate over fields
          for field in recList:
            if field[0].kind == nnkIdent:
              # Private field
              src &= level & "  #" & $field[0] & ";" & newLine
            elif field[0].kind == nnkPostfix:
              # Public field
              src &= level & "  " & $field[0][1].toStrLit & ";" & newLine
          src &= level & "}" & newLine
    
    # call any function
    elif statement.kind in nnkCallKinds:
      var args: seq[string] = @[]
      for i in 1..<statement.len:
        args.add($statement[i].toStrLit)
      src &= level & $statement[0].toStrLit & "(" & args.join(", ") & ");" & newLine
    
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
  ## .. code-block:: javascript
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
  # Clear compile time variables
  declaredVariables = @[]
  nimNodes = @[]
  enums = newTable[string, seq[string]]()
  # Build JS
  body.buildJsProc(emitSrc)
  # nim variables
  emitSrc = emitSrc.replace(re2"~([a-zA-Z][a-zA-Z0-9_]*)", "`$1`")
  # self -> this
  emitSrc = emitSrc.replace(re2"self\.([a-zA-Z][a-zA-Z0-9_]*)", "this.$1")
  when not defined(js) and not defined(docgen):
    throwDefect(
      HpxBuildJsDefect,
      "buildJs macro worked only on JS backend!",
      lineInfoObj(body)
    )

  result = newStmtList()
  # Split text for injecting Nim code  
  var
    i = 0
    splitted = emitSrc.split("![#=#]!")
  for text in splitted:
    if text.len != 0:
      result.add(newNimNode(nnkPragma).add(newColonExpr(
        ident"emit",
        newStrLitNode(text)
      )))
    if (i != splitted.len-1 or splitted.len == 1) and nimNodes.len != 0:
      result.add(nimNodes[i])
    inc i
