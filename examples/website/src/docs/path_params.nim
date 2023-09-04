# Import HappyX
import
  ../../../../src/happyx,
  ../ui/[colors, code, play_states, translations],
  ../components/[
    code_block_guide, code_block, code_block_slider
  ]


component PathParams:
  `template`:
    tDiv(class = "flex flex-col px-8 py-2 backdrop-blur-sm xl:h-fit gap-4"):
      tH1: {translate"Path Params 🔌"}
      tH2: {translate"Routing 🛠"}
      tP:
        {translate"HappyX provides powerful routing system. Here contains these features:"}
        tUl(class = "list-desc"):
          tLi: {translate"Path param validation (int/float/string/etc) 👮‍♀️"}
          if currentLanguage != "Python":
            tLi: {translate"Automatic [im]mutable variable creation ✨"}
          tLi: {translate"Supports by SPA/SSR and Nim/Python 👑"}
          tLi: {translate"Request models support 🛠"}
      tH2: {translate"Usage" & " ⚡"}

      component CodeBlockGuide(@[
        ("Nim", "nim", nimPathParamsSsr, cstring"nim_import_ssr", newPlayResult()),
        ("Nim (SPA)", "nim", nimPathParamsSpa, cstring"nim_import_ssr", newPlayResult()),
        ("Python", "python", pythonPathParamsSsr, cstring"py_import", newPlayResult()),
      ])

      tH2: {translate"Route Param Types 📕"}

      tTable:
        tTr:
          tTd(class = "font-bold"): {translate"Type"}
          tTd(class = "font-bold"): {translate"Usage"}
          tTd(class = "font-bold"): {translate"Usage alias"}
          tTd(class = "font-bold"): {translate"Description"}
        # Integer
        tTr:
          tTd:
            tSpan(class = "text-orange-800 dark:text-orange-400"):
              "int"
          tTd:
            tCode:
              tSpan(class = "text-green-800 dark:text-green-400"):
                "\"/"
              tSpan(class = "text-purple-800 dark:text-purple-400"):
                """{i:int}"""
              tSpan(class = "text-green-800 dark:text-green-400"):
                "\""
          tTd:
            tCode:
              tSpan(class = "text-green-800 dark:text-green-400"):
                "\"/"
              tSpan(class = "text-purple-800 dark:text-purple-400"):
                """$i:int"""
              tSpan(class = "text-green-800 dark:text-green-400"):
                "\""
          tTd: {translate"Parses param as integer value"}
        # Float
        tTr:
          tTd:
            tSpan(class = "text-orange-800 dark:text-orange-400"):
              "float"
          tTd:
            tCode:
              tSpan(class = "text-green-800 dark:text-green-400"):
                "\"/"
              tSpan(class = "text-purple-800 dark:text-purple-400"):
                """{i:float}"""
              tSpan(class = "text-green-800 dark:text-green-400"):
                "\""
          tTd:
            tCode:
              tSpan(class = "text-green-800 dark:text-green-400"):
                "\"/"
              tSpan(class = "text-purple-800 dark:text-purple-400"):
                """$i:float"""
              tSpan(class = "text-green-800 dark:text-green-400"):
                "\""
          tTd: {translate"Parses param as float value"}
        # Boolean
        tTr:
          tTd:
            tSpan(class = "text-orange-800 dark:text-orange-400"):
              "bool"
          tTd:
            tCode:
              tSpan(class = "text-green-800 dark:text-green-400"):
                "\"/"
              tSpan(class = "text-purple-800 dark:text-purple-400"):
                """{i:bool}"""
              tSpan(class = "text-green-800 dark:text-green-400"):
                "\""
          tTd:
            tCode:
              tSpan(class = "text-green-800 dark:text-green-400"):
                "\"/"
              tSpan(class = "text-purple-800 dark:text-purple-400"):
                """$i:bool"""
              tSpan(class = "text-green-800 dark:text-green-400"):
                "\""
          tTd: {translate"Parses param as boolean value"}
        # Word
        tTr:
          tTd:
            tSpan(class = "text-orange-800 dark:text-orange-400"):
              "word"
          tTd:
            tCode:
              tSpan(class = "text-green-800 dark:text-green-400"):
                "\"/"
              tSpan(class = "text-purple-800 dark:text-purple-400"):
                """{i:word}"""
              tSpan(class = "text-green-800 dark:text-green-400"):
                "\""
          tTd:
            tCode:
              tSpan(class = "text-green-800 dark:text-green-400"):
                "\"/"
              tSpan(class = "text-purple-800 dark:text-purple-400"):
                """$i:word"""
              tSpan(class = "text-green-800 dark:text-green-400"):
                "\""
          tTd: {translate"Parses param as word (only \w)"}
        # String
        tTr:
          tTd:
            tSpan(class = "text-orange-800 dark:text-orange-400"):
              "string"
          tTd:
            tCode:
              tSpan(class = "text-green-800 dark:text-green-400"):
                "\"/"
              tSpan(class = "text-purple-800 dark:text-purple-400"):
                """{i:string}"""
              tSpan(class = "text-green-800 dark:text-green-400"):
                "\""
          tTd:
            tCode:
              tSpan(class = "text-green-800 dark:text-green-400"):
                "\"/"
              tSpan(class = "text-purple-800 dark:text-purple-400"):
                """$i:string"""
              tSpan(class = "text-green-800 dark:text-green-400"):
                "\""
          tTd: {translate"Parses param as string (any character exclude '/')"}
        # String
        tTr:
          tTd:
            tSpan(class = "text-orange-800 dark:text-orange-400"):
              "path"
          tTd:
            tCode:
              tSpan(class = "text-green-800 dark:text-green-400"):
                "\"/"
              tSpan(class = "text-purple-800 dark:text-purple-400"):
                """{i:path}"""
              tSpan(class = "text-green-800 dark:text-green-400"):
                "\""
          tTd:
            tCode:
              tSpan(class = "text-green-800 dark:text-green-400"):
                "\"/"
              tSpan(class = "text-purple-800 dark:text-purple-400"):
                """$i:path"""
              tSpan(class = "text-green-800 dark:text-green-400"):
                "\""
          tTd: {translate"Parses param as string (any character include '/')"}
        # Enums
        if currentLanguage != "Python":
          tTr:
            tTd:
              tSpan(class = "text-orange-800 dark:text-orange-400"):
                "enum(ENUM_NAME)"
            tTd:
              tCode:
                tSpan(class = "text-green-800 dark:text-green-400"):
                  "\"/"
                tSpan(class = "text-purple-800 dark:text-purple-400"):
                  """{i:enum(Language)}"""
                tSpan(class = "text-green-800 dark:text-green-400"):
                  "\""
            tTd:
              tCode:
                tSpan(class = "text-green-800 dark:text-green-400"):
                  "\"/"
                tSpan(class = "text-purple-800 dark:text-purple-400"):
                  """$i:enum(Language)"""
                tSpan(class = "text-green-800 dark:text-green-400"):
                  "\""
            tTd: {translate"Parses param as Nim enum type (allow only for string enums)"}
        # Regex
        tTr:
          tTd:
            tSpan(class = "text-orange-800 dark:text-orange-400"):
              "regex"
          tTd:
            tCode:
              tSpan(class = "text-green-800 dark:text-green-400"):
                "\"/"
              tSpan(class = "text-purple-800 dark:text-purple-400"):
                """{i:/REGEX/}"""
              tSpan(class = "text-green-800 dark:text-green-400"):
                "\""
          tTd:
            tCode:
              tSpan(class = "text-green-800 dark:text-green-400"):
                "\"/"
              tSpan(class = "text-purple-800 dark:text-purple-400"):
                """$i:/REGEX/"""
              tSpan(class = "text-green-800 dark:text-green-400"):
                "\""
          tTd: {translate"Parses param as string with regex pattern"}
      
      {translate"In addition, you can define your own parameter types ✌"}

      component CodeBlockGuide(@[
        ("Nim", "nim", nimCustomPathParamTypeSsr, cstring"nim_import_ssr", newPlayResult()),
        ("Nim (SPA)", "nim", nimCustomPathParamTypeSpa, cstring"nim_import_ssr", newPlayResult()),
        ("Python", "python", pythonCustomRouteParamType, cstring"py_import", newPlayResult()),
      ])

      if currentLanguage != "Python":
        tH2: {translate"Assigning Route Params 🛠"}

        tP:
          {translate"At Nim side you can assign route params and use it anywhere"}

        tDiv(class = "flex gap-16 items-center justify-center items-center w-full"):
          tDiv(class = "flex flex-col gap-4"):
            tH3: {translate"SSR Example ⚡"}
            tP: {translate"Server-side rendering application"}
            component CodeBlock(language = "nim", source = nimAssignRouteParamsSsr, id = "assignRouteParamsSsr")
          tDiv(class = "flex flex-col gap-4"):
            tH3: {translate"SPA Example 🎴"}
            tP: {translate"Single-page application"}
            component CodeBlock(language = "nim", source = nimAssignRouteParamsSpa, id = "assignRouteParamsSpa")
