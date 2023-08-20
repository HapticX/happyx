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
##        return translate("Hello, world!")
## 

import
  macros,
  strtabs,
  tables,
  strformat,
  ../core/[exceptions]


type
  LanguageSettings* = object
    lang*: string


var
  translatesStatement* {. compileTime .} = newStmtList()
  translatesCompileTime* {. compileTime .} =
    when defined(js):
      newTable[cstring, TableRef[cstring, string]]()
    else:
      newTable[string, StringTableRef]()


macro translatable*(body: untyped): untyped =
  ## Make translations for strings
  ## 
  ## > Use standalone file with your translations for good practice.
  ## 
  ## # Example
  ## 
  ## .. code-block:: nim
  ##    translatable:
  ##      # If lang is unknown than used "My own string"
  ##      "My own string":
  ##        "ru" -> "Моя собственная строка"
  ##        "fr" -> "..."
  ## 
  let
    translations = ident"translates"
  if translatesStatement.len == 0:
    when defined(js):
      translatesStatement.add(newVarStmt(
        postfix(translations, "*"), # newNimNode(nnkPragmaExpr).add(ident"translates", newNimNode(nnkPragma).add(ident"global")),
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
      translatesStatement.add(newVarStmt(translations, newCall(
        newNimNode(nnkBracketExpr).add(
          ident"newTable", ident"string", ident"StringTableRef"
        )
      )))
  for s in body:
    if s.kind == nnkCall and s[0].kind in [nnkStrLit, nnkTripleStrLit] and s[1].kind == nnkStmtList:
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
            newNimNode(nnkBracketExpr).add(translations, source),
            newCall(newNimNode(nnkBracketExpr).add(
              ident"newTable", ident"cstring", ident"string"
            ))
          )
        else:
          newAssignment(
            newNimNode(nnkBracketExpr).add(translations, source),
            newCall("newStringTable")
          ),
        newAssignment(
          newNimNode(nnkBracketExpr).add(
            newNimNode(nnkBracketExpr).add(translations, source),
            newStrLitNode("default")
          ),
          source
        )
      )
      for t in s[1]:
        if t.kind == nnkInfix and t[0] == ident"->" and t[1].kind in [nnkStrLit, nnkTripleStrLit] and t[2].kind in [nnkStrLit, nnkTripleStrLit]:
          translatesCompileTime[sourceStr][$t[1]] = $t[2]
          translatesStatement.add(
            newAssignment(
              newNimNode(nnkBracketExpr).add(
                newNimNode(nnkBracketExpr).add(translations, source),
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
  when defined(js):
    return translatesStatement


macro translate*(self: static[string] | string): string =
  ## Translates `self` string to current client language (SPA) or accept-language header (SSG/SSR)
  let
    language =
      newNimNode(nnkIfExpr).add(
        newNimNode(nnkElifBranch).add(
          when defined(js):
            newCall("==", newDotExpr(newDotExpr(ident"languageSettings", ident"val"), ident"lang"), newLit"auto")
          else:
            newCall("==", newDotExpr(ident"languageSettings", ident"lang"), newLit"auto"),
          when defined(js):
            newDotExpr(ident"navigator", ident"language")
          else:
            ident"acceptLanguage"
        ), newNimNode(nnkElse).add(
          when defined(js):
            newDotExpr(newDotExpr(ident"languageSettings", ident"val"), ident"lang")
          else:
            newDotExpr(ident"languageSettings", ident"lang")
        )
      )
    source =
      when self is static[string]:
        newStrLitNode(self)
      else:
        self
    translations = ident"translates"
  
  when self is static[string]:
    if not translatesCompileTime.hasKey(self):
      return newStrLitNode($self)
  
  result = newNimNode(nnkIfStmt).add(
    newNimNode(nnkElifBranch).add(
      newCall("not",
        newCall(
          "hasKey",
          newNimNode(nnkBracketExpr).add(
            translations, source
          ),
          language
        )
      ),
      newNimNode(nnkBracketExpr).add(
        newNimNode(nnkBracketExpr).add(
          translations, source
        ),
        newStrLitNode("default")
      )
    ), newNimNode(nnkElse).add(
      newNimNode(nnkBracketExpr).add(
        newNimNode(nnkBracketExpr).add(
          translations, source
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
          translations, source
        )
      ),
      source
    ))
