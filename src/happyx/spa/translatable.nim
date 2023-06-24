## # Translatable strings ✨
## > Provides DSL for autotranslatable strings
## 
## With this module you can easily write multilanguage programs!
## 
## ## Minimal Example 👨‍🔬
## 
## .. code-block:: nim
##    translable:
##      "Hello, world!":
##        # "Hello, world!" by default
##        "ru" -> "Привет, мир!"
##        "fr" -> "Bonjour, monde!"
##    serve("127.0.0.1", 5000):
##      get "/":
##        return translatable("Hello, world!")
## 

import
  macros,
  strtabs,
  tables,
  strformat,
  ../core/[constants, exceptions]


var
  translatesStatement* {. compileTime .} = newStmtList()
  translatesCompileTime* {. compileTime .} =
    when defined(js):
      newTable[cstring, TableRef[cstring, string]]()
    else:
      newTable[string, StringTableRef]()


macro translatable*(body: untyped): untyped =
  ## Make strings translatable
  ## 
  ## # Example
  ## 
  ## .. code-block:: nim
  ##    translatable:
  ##      "My own string":
  ##        "ru" -> "Моя собственная строка"
  ## 
  if translatesStatement.len == 0:
    when defined(js):
      translatesStatement.add(newVarStmt(
        ident"translates", # newNimNode(nnkPragmaExpr).add(ident"translates", newNimNode(nnkPragma).add(ident"global")),
        newCall(
        newNimNode(nnkBracketExpr).add(
            ident"newTable", ident"cstring",
            newNimNode(nnkBracketExpr).add(
              ident"TableRef", ident"cstring", ident"string"
            )
          )
        )
      ))
    else:
      translatesStatement.add(newVarStmt(ident"translates", newCall(
        newNimNode(nnkBracketExpr).add(
          ident"newTable", ident"string", ident"StringTableRef"
        )
      )))
  for s in body:
    if s.kind == nnkCall and s[0].kind == nnkStrLit and s[1].kind == nnkStmtList:
      let
        source = s[0]  # source string
        sourceStr = $s[0]  # source string
      when defined(js):
        translatesCompileTime[sourceStr] = newTable[cstring, string]()
      else:
        translatesCompileTime[sourceStr] = newStringTable()
      translatesCompileTime[sourceStr]["default"] = sourceStr
      translatesStatement.add(
        when defined(js):
          newAssignment(
            newNimNode(nnkBracketExpr).add(ident"translates", source),
            newCall(newNimNode(nnkBracketExpr).add(
              ident"newTable", ident"cstring", ident"string"
            ))
          )
        else:
          newAssignment(
            newNimNode(nnkBracketExpr).add(ident"translates", source),
            newCall("newStringTable")
          ),
        newAssignment(
          newNimNode(nnkBracketExpr).add(
            newNimNode(nnkBracketExpr).add(ident"translates", source),
            newStrLitNode("default")
          ),
          source
        )
      )
      for t in s[1]:
        if t.kind == nnkInfix and t[0] == ident"->" and t[1].kind == nnkStrLit and t[2].kind == nnkStrLit:
          translatesCompileTime[sourceStr][$t[1]] = $t[2]
          translatesStatement.add(
            newAssignment(
              newNimNode(nnkBracketExpr).add(
                newNimNode(nnkBracketExpr).add(ident"translates", source),
                t[1]
              ),
              t[2]
            )
          )
        else:
          throwDefect(
            HpxTranslatableDefect,
            "Invalid translatable syntax: ",
            lineInfoObj(t)
          )
    else:
      throwDefect(
        HpxTranslatableDefect,
        "Invalid translatable syntax: ",
        lineInfoObj(s)
      )


macro translate*(self: static[string] | string): string =
  ## Translates `self` string to current client language (SPA) or accept-language header (SSG/SSR)
  let
    language =
      when defined(js):
        newDotExpr(ident"navigator", ident"language")
      else:
        ident"acceptLanguage"
    source =
      when self is static[string]:
        newStrLitNode(self)
      else:
        self
  
  when self is static[string]:
    if not translatesCompileTime.hasKey(self):
      return newStrLitNode($self)
  
  result = newNimNode(nnkIfStmt).add(
    newNimNode(nnkElifBranch).add(
      newCall("not",
        newCall(
          "hasKey",
          newNimNode(nnkBracketExpr).add(
            ident"translates", source
          ),
          language
        )
      ),
      newNimNode(nnkBracketExpr).add(
        newNimNode(nnkBracketExpr).add(
          ident"translates", source
        ),
        newStrLitNode("default")
      )
    ), newNimNode(nnkElse).add(
      newNimNode(nnkBracketExpr).add(
        newNimNode(nnkBracketExpr).add(
          ident"translates", source
        ),
        language
      )
    )
  )
  when not (self is static[string]):
    result.insert(0, newNimNode(nnkElifBranch).add(
      newCall("not",
        newCall(
          "hasKey",
          ident"translates", source
        )
      ),
      source
    ))
