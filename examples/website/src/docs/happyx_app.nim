# Import HappyX
import
  ../../../../src/happyx,
  ../ui/[colors, code, play_states, translations],
  ../components/[
    code_block_guide, code_block
  ]


component HappyxApp:
  `template`:
    tDiv(class = "flex flex-col px-8 py-2 backdrop-blur-sm xl:h-fit gap-4"):
      tH1: {translate("HappyX Application 🍍")}

      tP:
        {translate("In this guide we create calculator app 🧮")}

      tH2: {translate("Create Application 📦")}

      tDiv(class = "grid grid-cols-1 xl:grid-cols-3 gap-4"):
        tDiv(class = "flex flex-col gap-4 xl:col-span-2"):
          tP:
            {translate("To create a new HappyX app you should use ")}
            tCode: "CLI"
            {translate(" or follow project structure.")}
          tP:
            {translate("When you use CLI, HappyX do everything for you.")}
          
          component CodeBlockGuide(@[
            ("Nim", "shell", "hpx create --name:calculator --kind:SSR", cstring"nim_proj_ssr", playCreateSsrProject),
            ("Nim (SPA)", "shell", "hpx create --name:calculator --use-tailwind --kind:SPA", cstring"nim_proj_ssr", playCreateSpaProject),
            ("Python", "shell", "hpx create --name:calculator --language:Python", cstring"py_proj", playCreateSsrProjectPython),
          ])

        tDiv:
          tP: {translate("Project Structure")}
          component CodeBlockGuide(@[
            ("Nim", "plaintext", nimProjectSsr, cstring"nim_proj_ssr", newPlayResult()),
            ("Nim (SPA)", "plaintext", nimProjectSpa, cstring"nim_proj_ssr", newPlayResult()),
            ("Python", "plaintext", pythonProject, cstring"py_proj", newPlayResult()),
          ])
        
      tH2: {translate("Calculator Project 🧮")}

      tH3: {translate("Import Library")}
      if currentLanguage in ["Nim", "Nim (SPA)"]:
        tP:
          {translate("To use ")}
          tCode: "HappyX"
          {translate(" on Nim we need to import it.")}
      elif currentLanguage == "Python":
        tP:
          {translate("In this guide we need only ")}
          tCode: "new_server"
          {translate(" function. So import it.")}
        
      component CodeBlockGuide(@[
        ("Nim", "nim", "import happyx", cstring"nim_import_ssr", newPlayResult()),
        ("Nim (SPA)", "nim", "import happyx", cstring"nim_import_ssr", newPlayResult()),
        ("Python", "python", "from happyx import new_server", cstring"py_import", newPlayResult()),
      ])

      if currentLanguage == "Nim":
        tH3: {translate("Server ✨")}
        tP:
          {translate("Next step is server declaration.")}
        
        tP:
          {translate("Here we declare ")}
          tB(class = "text-purple-700 dark:text-purple-400"): "serve"
          {translate(" with ")}
          tB: {translate("IP-address")}
          {translate(" and ")}
          tB: {translate("port")}
          "."
      elif currentLanguage == "Nim (SPA)":
        tH3: {translate("Web App ✨")}
        tP:
          {translate("Next step is main app declaration.")}
        
        tP:
          {translate("Here we declare ")}
          tB(class = "text-purple-700 dark:text-purple-400"): "appRoutes"
          {translate(" with ")}
          tB: {translate("element ID")}
          {translate(" that will contain our app.")}
      elif currentLanguage == "Python":
        tH3: {translate("Server ✨")}
        tP:
          {translate("Next step is main app declaration.")}
        
        tP:
          {translate("Here we declare server with ")}
          tB: {translate("IP-address")}
          {translate(" and ")}
          tB: {translate("port")}
          "."
        
      component CodeBlockGuide(@[
        ("Nim", "nim", "serve \"127.0.0.1\", 5000:\n  discard", cstring"nim_server_ssr", newPlayResult()),
        ("Nim (SPA)", "nim", "appRoutes \"app\":\n  discard", cstring"nim_server_ssr", newPlayResult()),
        ("Python", "python", "app = new_server('127.0.0.1', 5000)", cstring"py_server", newPlayResult()),
      ])

      tP:
        {translate("Next we create ")}
        tB: "calculator"
        {translate(" route.")}

      component CodeBlockGuide(@[
        ("Nim", "nim", "serve \"127.0.0.1\", 5000:\n  get \"/calc/{left:float}/{op}/{right:float}\":\n    discard", cstring"nim_server_ssr", newPlayResult()),
        ("Nim (SPA)", "nim", "appRoutes \"app\":\n  \"/calc/{left:float}/{op}/{right:float}\":\n    discard", cstring"nim_server_ssr", newPlayResult()),
        ("Python", "python", "@app.get('/calc/{left}/{op}/{right}')\ndef calculate(left: float, right: float, op: str):\n    pass", cstring"py_server", newPlayResult()),
      ])

      tP:
        {translate("Here we declare route that contains three path params.")}
      
      tH3: {translate("Calculation 🧮")}

      component CodeBlockGuide(@[
        ("Nim", "nim", nimSsrCalc, cstring"nim_server_ssr", newPlayResult()),
        ("Nim (SPA)", "nim", nimSpaCalc, cstring"nim_server_ssr", newPlayResult()),
        ("Python", "python", pythonSsrCalc, cstring"py_server", newPlayResult()),
      ])
