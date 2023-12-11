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
          if currentLanguage in ["Nim", "Nim (SPA)"]:
            tLi: {translate"Automatic [im]mutable variable creation ✨"}
          tLi: {translate"Supports with any project type"}
          tLi: {translate"Request models support 🛠"}
          tLi: {translate"Custom types support 🔥"}
      tH2: {translate"Usage" & " ⚡"}

      CodeBlockGuide(@[
        ("Nim", "nim", nimPathParamsSsr, cstring"nim_import_ssr", newPlayResult()),
        ("Nim (SPA)", "nim", nimPathParamsSpa, cstring"nim_import_ssr", newPlayResult()),
        ("Python", "python", pythonPathParamsSsr, cstring"py_import", newPlayResult()),
        ("JavaScript", "javascript", jsPathParamsSsr, cstring"js_import", newPlayResult()),
        ("TypeScript", "typescript", tsPathParamsSsr, cstring"ts_import", newPlayResult()),
      ])

      tH2: {translate"Route Param Types 📕"}

      tDiv(class = "overflow-x-auto w-full"): tTable:
        tTr:
          tTd(class = "font-bold text-center"): {translate"Type"}
          tTd(class = "font-bold text-center"): {translate"Usage"}
          tTd(class = "font-bold text-center"): {translate"Usage alias"}
          tTd(class = "font-bold text-center"): {translate"Description"}
        # Integer
        tTr:
          tTd(class = "text-center"):
            tSpan(class = "text-orange-800 dark:text-orange-400"):
              "int"
          tTd(class = "text-center"):
            tCode:
              tSpan(class = "text-green-800 dark:text-green-400"):
                "\"/"
              tSpan(class = "text-purple-800 dark:text-purple-400"):
                """{i:int}"""
              tSpan(class = "text-green-800 dark:text-green-400"):
                "\""
          tTd(class = "text-center"):
            tCode:
              tSpan(class = "text-green-800 dark:text-green-400"):
                "\"/"
              tSpan(class = "text-purple-800 dark:text-purple-400"):
                """$i:int"""
              tSpan(class = "text-green-800 dark:text-green-400"):
                "\""
          tTd(class = "text-center"): {translate"Parses param as integer value"}
        # Float
        tTr:
          tTd(class = "text-center"):
            tSpan(class = "text-orange-800 dark:text-orange-400"):
              "float"
          tTd(class = "text-center"):
            tCode:
              tSpan(class = "text-green-800 dark:text-green-400"):
                "\"/"
              tSpan(class = "text-purple-800 dark:text-purple-400"):
                """{i:float}"""
              tSpan(class = "text-green-800 dark:text-green-400"):
                "\""
          tTd(class = "text-center"):
            tCode:
              tSpan(class = "text-green-800 dark:text-green-400"):
                "\"/"
              tSpan(class = "text-purple-800 dark:text-purple-400"):
                """$i:float"""
              tSpan(class = "text-green-800 dark:text-green-400"):
                "\""
          tTd(class = "text-center"): {translate"Parses param as float value"}
        # Boolean
        tTr:
          tTd(class = "text-center"):
            tSpan(class = "text-orange-800 dark:text-orange-400"):
              "bool"
          tTd(class = "text-center"):
            tCode:
              tSpan(class = "text-green-800 dark:text-green-400"):
                "\"/"
              tSpan(class = "text-purple-800 dark:text-purple-400"):
                """{i:bool}"""
              tSpan(class = "text-green-800 dark:text-green-400"):
                "\""
          tTd(class = "text-center"):
            tCode:
              tSpan(class = "text-green-800 dark:text-green-400"):
                "\"/"
              tSpan(class = "text-purple-800 dark:text-purple-400"):
                """$i:bool"""
              tSpan(class = "text-green-800 dark:text-green-400"):
                "\""
          tTd(class = "text-center"): {translate"Parses param as boolean value"}
        # Word
        tTr:
          tTd(class = "text-center"):
            tSpan(class = "text-orange-800 dark:text-orange-400"):
              "word"
          tTd(class = "text-center"):
            tCode:
              tSpan(class = "text-green-800 dark:text-green-400"):
                "\"/"
              tSpan(class = "text-purple-800 dark:text-purple-400"):
                """{i:word}"""
              tSpan(class = "text-green-800 dark:text-green-400"):
                "\""
          tTd(class = "text-center"):
            tCode:
              tSpan(class = "text-green-800 dark:text-green-400"):
                "\"/"
              tSpan(class = "text-purple-800 dark:text-purple-400"):
                """$i:word"""
              tSpan(class = "text-green-800 dark:text-green-400"):
                "\""
          tTd(class = "text-center"): {translate"Parses param as word (only \w+)"}
        # String
        tTr:
          tTd(class = "text-center"):
            tSpan(class = "text-orange-800 dark:text-orange-400"):
              "string"
          tTd(class = "text-center"):
            tCode:
              tSpan(class = "text-green-800 dark:text-green-400"):
                "\"/"
              tSpan(class = "text-purple-800 dark:text-purple-400"):
                """{i:string}"""
              tSpan(class = "text-green-800 dark:text-green-400"):
                "\""
          tTd(class = "text-center"):
            tCode:
              tSpan(class = "text-green-800 dark:text-green-400"):
                "\"/"
              tSpan(class = "text-purple-800 dark:text-purple-400"):
                """$i:string"""
              tSpan(class = "text-green-800 dark:text-green-400"):
                "\""
          tTd(class = "text-center"): {translate"Parses param as string (any character exclude '/')"}
        # String
        tTr:
          tTd(class = "text-center"):
            tSpan(class = "text-orange-800 dark:text-orange-400"):
              "path"
          tTd(class = "text-center"):
            tCode:
              tSpan(class = "text-green-800 dark:text-green-400"):
                "\"/"
              tSpan(class = "text-purple-800 dark:text-purple-400"):
                """{i:path}"""
              tSpan(class = "text-green-800 dark:text-green-400"):
                "\""
          tTd(class = "text-center"):
            tCode:
              {translate"not available"}
          tTd(class = "text-center"): {translate"Parses param as string (any character include '/')"}
        # Enums
        if currentLanguage.val in ["Nim", "Nim (SPA)"]:
          tTr:
            tTd(class = "text-center"):
              tSpan(class = "text-orange-800 dark:text-orange-400"):
                "enum(NAME)"
            tTd(class = "text-center"):
              tCode:
                tSpan(class = "text-green-800 dark:text-green-400"):
                  "\"/"
                tSpan(class = "text-purple-800 dark:text-purple-400"):
                  """{i:enum(Option)}"""
                tSpan(class = "text-green-800 dark:text-green-400"):
                  "\""
            tTd(class = "text-center"):
              tCode:
                tSpan(class = "text-green-800 dark:text-green-400"):
                  "\"/"
                tSpan(class = "text-purple-800 dark:text-purple-400"):
                  """$i:enum(Option)"""
                tSpan(class = "text-green-800 dark:text-green-400"):
                  "\""
            tTd(class = "text-center"): {translate"Parses param as Nim enum type (allow only for string enums)"}
        # Regex
        tTr:
          tTd(class = "text-center"):
            tSpan(class = "text-orange-800 dark:text-orange-400"):
              "regex"
          tTd(class = "text-center"):
            tCode:
              tSpan(class = "text-green-800 dark:text-green-400"):
                "\"/"
              tSpan(class = "text-purple-800 dark:text-purple-400"):
                """{i:/REGEX/}"""
              tSpan(class = "text-green-800 dark:text-green-400"):
                "\""
          tTd(class = "text-center"):
            tCode:
              {translate"not available"}
          tTd(class = "text-center"): {translate"Parses param as string with regex pattern"}
      
      tP:
        {translate"In addition to using typed path parameters, you can explicitly specify that they are mutable and/or optional, and you can also specify a default value"}
      
      tP:
        {translate"Here is few examples:"}
      
      tDiv(class = "overflow-x-auto w-full"): tTable:
        tTr:
          tTd(class = "font-bold text-center"): {translate"Example"}
          tTd(class = "font-bold text-center"): {translate"Type"}
          tTd(class = "font-bold text-center"): {translate"Usage"}
          tTd(class = "font-bold text-center"): {translate"Description"}
        # optional integer
        tTr:
          tTd(class = "text-center"):
            {translate"Optional integer"}
          tTd(class = "text-center"):
            tSpan(class = "text-orange-800 dark:text-orange-400"): "int"
          tTd(class = "text-center"):
            tCode:
              tSpan(class = "text-green-800 dark:text-green-400"): "\"/"
              tSpan(class = "text-purple-800 dark:text-purple-400"): """{i?:int}"""
              tSpan(class = "text-green-800 dark:text-green-400"): "\""
          tTd(class = "text-center"):
            {translate"Optional path param typed as int with default value 0"}
        # optional bool with default value
        tTr:
          tTd(class = "text-center"):
            {translate"default bool"}
          tTd(class = "text-center"):
            tSpan(class = "text-orange-800 dark:text-orange-400"): "bool"
          tTd(class = "text-center"):
            tCode:
              tSpan(class = "text-green-800 dark:text-green-400"): "\"/"
              tSpan(class = "text-purple-800 dark:text-purple-400"): """{b?:bool=false}"""
              tSpan(class = "text-green-800 dark:text-green-400"): "\""
          tTd(class = "text-center"):
            {translate"Optional path param typed as bool with default value false"}
        # mutable default float
        tTr:
          tTd(class = "text-center"):
            {translate"mutable default float"}
          tTd(class = "text-center"):
            tSpan(class = "text-orange-800 dark:text-orange-400"): "float"
          tTd(class = "text-center"):
            tCode:
              tSpan(class = "text-green-800 dark:text-green-400"): "\"/"
              tSpan(class = "text-purple-800 dark:text-purple-400"): """{f:float[m]=3.14}"""
              tSpan(class = "text-green-800 dark:text-green-400"): "\""
          tTd(class = "text-center"):
            {translate"Optional mutable path param typed as float with default value 3.14"}
        # mutable string
        tTr:
          tTd(class = "text-center"):
            {translate"mutable string"}
          tTd(class = "text-center"):
            tSpan(class = "text-orange-800 dark:text-orange-400"): "string"
          tTd(class = "text-center"):
            tCode:
              tSpan(class = "text-green-800 dark:text-green-400"): "\"/"
              tSpan(class = "text-purple-800 dark:text-purple-400"): """{s:string[m]}"""
              tSpan(class = "text-green-800 dark:text-green-400"): "\""
          tTd(class = "text-center"):
            {translate"Mutable path param typed as string"}
      
      tP:
        {translate"In addition, you can define your own parameter types ✌"}

      CodeBlockGuide(@[
        ("Nim", "nim", nimCustomPathParamTypeSsr, cstring"nim_import_ssr", newPlayResult()),
        ("Nim (SPA)", "nim", nimCustomPathParamTypeSpa, cstring"nim_import_ssr", newPlayResult()),
        ("Python", "python", pythonCustomRouteParamType, cstring"py_import", newPlayResult()),
        ("JavaScript", "javascript", jsCustomRouteParamType, cstring"js_import", newPlayResult()),
        ("TypeScript", "typescript", tsCustomRouteParamType, cstring"ts_import", newPlayResult()),
      ])

      if currentLanguage.val in ["Nim", "Nim (SPA)"]:
        tH2: {translate"Assigning Route Params 🛠"}

        tP:
          {translate"At Nim side you can assign route params and use it anywhere"}

        tDiv(class = "flex flex-col lg:flex-row gap-16 items-center justify-between items-center w-full"):
          tDiv(class = "flex flex-col gap-4"):
            tH3: {translate"SSR Example ⚡"}
            tP: {translate"Server-side rendering application"}
            CodeBlock(language = "nim", source = nimAssignRouteParamsSsr, id = "assignRouteParamsSsr")
          tDiv(class = "flex flex-col gap-4"):
            tH3: {translate"SPA Example 🎴"}
            tP: {translate"Single-page application"}
            CodeBlock(language = "nim", source = nimAssignRouteParamsSpa, id = "assignRouteParamsSpa")
