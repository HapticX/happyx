# Import HappyX
import
  ../../../../src/happyx,
  ../ui/[colors, code, play_states, translations],
  ../components/[
    code_block_guide, code_block
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
          tLi: {translate"Automatic [im]mutable variable creation ✨"}
          tLi: {translate"Supports by SPA/SSR and Nim/Python"}
      tH2: {translate"Usage ⚡"}

      component CodeBlockGuide(@[
        ("Nim", "nim", nimPathParamsSsr, cstring"nim_import_ssr", newPlayResult()),
        ("Nim (SPA)", "nim", nimPathParamsSpa, cstring"nim_import_ssr", newPlayResult()),
        ("Python", "python", pythonPathParamsSsr, cstring"py_import", newPlayResult()),
      ])
