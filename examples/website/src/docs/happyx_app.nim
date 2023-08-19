# Import HappyX
import
  ../../../../src/happyx,
  ../ui/colors,
  ../ui/code,
  ../ui/play_states,
  ../components/[
    code_block_guide, code_block
  ]


component HappyxApp:
  `template`:
    tDiv(class = "flex flex-col px-8 py-2 backdrop-blur-sm xl:h-fit gap-4"):
      tH1: "HappyX Application 🍍"

      tP:
        "In this guide we create calculator app 🧮"

      tH2: "Create Application 📦"

      tDiv(class = "grid grid-cols-1 xl:grid-cols-3 gap-4"):
        tDiv(class = "flex flex-col gap-4 xl:col-span-2"):
          tP:
            "To create a new HappyX app you should use "
            tCode: "CLI"
            " or follow project structure."
          tP:
            "When you use CLI, HappyX do everything for you."
          
          component CodeBlockGuide(@[
            ("Nim", "shell", "hpx create --name:calculator --kind:SSR", cstring"nim_proj_ssr", playCreateSsrProject),
            ("Nim (SPA)", "shell", "hpx create --name:calculator --use-tailwind --kind:SPA", cstring"nim_proj_ssr", playCreateSpaProject),
            ("Python", "shell", "hpx create --name:calculator --language:Python", cstring"py_proj", playCreateSsrProjectPython),
          ])

        tDiv:
          tP: "Project Structure"
          component CodeBlockGuide(@[
            ("Nim", "plaintext", nimProjectSsr, cstring"nim_proj_ssr", newPlayResult()),
            ("Nim (SPA)", "plaintext", nimProjectSpa, cstring"nim_proj_ssr", newPlayResult()),
            ("Python", "plaintext", pythonProject, cstring"py_proj", newPlayResult()),
          ])
        
      tH2: "Calculator Project 🧮"

      tH3: "Import Library"
      if currentLanguage in ["Nim", "Nim (SPA)"]:
        tP:
          "To use "
          tCode: "HappyX"
          " on Nim we need to import it."
      elif currentLanguage == "Python":
        tP:
          "In this guide we need only "
          tCode: "new_server"
          " function. So import it."
        
      component CodeBlockGuide(@[
        ("Nim", "nim", "import happyx", cstring"nim_import_ssr", newPlayResult()),
        ("Nim (SPA)", "nim", "import happyx", cstring"nim_import_ssr", newPlayResult()),
        ("Python", "python", "from happyx import new_server", cstring"py_import", newPlayResult()),
      ])

      if currentLanguage == "Nim":
        tP:
          "Next step is server declaration."
        
        tP:
          "Here we declare "
          tB(class = "text-purple-700 dark:text-purple-400"): "serve"
          " with "
          tB: "IP-address"
          " and "
          tB: "port"
          "."
      elif currentLanguage == "Nim (SPA)":
        tP:
          "Next step is main app declaration."
        
        tP:
          "Here we declare "
          tB(class = "text-purple-700 dark:text-purple-400"): "appRoutes"
          " with "
          tB: "element ID"
          " that will contain our app."
      elif currentLanguage == "Python":
        tP:
          "Next step is main app declaration."
        
        tP:
          "Here we declare server with "
          tB: "IP-address"
          " and "
          tB: "port"
          "."
        
      component CodeBlockGuide(@[
        ("Nim", "nim", "serve \"127.0.0.1\", 5000:\n  discard", cstring"nim_server_ssr", newPlayResult()),
        ("Nim (SPA)", "nim", "appRoutes \"app\":\n  discard", cstring"nim_server_ssr", newPlayResult()),
        ("Python", "python", "app = new_server('127.0.0.1', 5000)", cstring"py_server", newPlayResult()),
      ])
