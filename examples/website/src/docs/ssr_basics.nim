# Import HappyX
import
  ../../../../src/happyx,
  ../ui/[colors, code, play_states, translations],
  ../components/[
    code_block_guide, code_block, code_block_slider
  ]


component SsrBasics:
  `template`:
    tDiv(class = "flex flex-col px-8 py-2 xl:h-fit gap-4"):
      tH1: {translate"Server-side Applications Basics 🖥"}

      tP: {translate"This section will provide you with an overview of the core features and capabilities of SSR within HappyX web framework. SSR is a powerful technique that allows you to render web pages on the server-side before sending them to the client, resulting in improved performance and SEO optimization."}

      tP: {translate"HappyX server-side allows to use it from Nim, Python and NodeJS!"}

      if currentLanguage.val in ["Nim", "Python", "TypeScript", "JavaScript"]:
        tP: {translate"Minimal example in any supported language seems like that:"}
        
        CodeBlockGuide(@[
          ("Nim", "nim", nimSsrHelloWorldExample, cstring"nim_import_ssr", newPlayResult()),
          ("Python", "python", pythonHelloWorldExample, cstring"py_import", newPlayResult()),
          ("JavaScript", "javascript", jsHelloWorldExample, cstring"js_import", newPlayResult()),
          ("TypeScript", "typescript", tsHelloWorldExample, cstring"ts_import", newPlayResult()),
        ])
      
      tH2: {translate"Headers, Status Code And Cookies 📦"}
      tP:
        {translate"In any web framework you can work with status code, headers, cookies, etc. So HappyX give you it!"}
      
      CodeBlockGuide(@[
        ("Nim", "nim", nimSsrAdvancedHelloWorld, cstring"nim_advanced", newPlayResult()),
        ("Python", "python", pySsrAdvancedHelloWorld, cstring"py_advanced", newPlayResult()),
        ("JavaScript", "javascript", jsSsrAdvancedHelloWorld, cstring"js_advanced", newPlayResult()),
        ("TypeScript", "typescript", tsSsrAdvancedHelloWorld, cstring"ts_advanced", newPlayResult()),
      ])

      tH2: {translate"Helpful Routes 🔌"}
      if currentLanguage == "Nim":
        tP:
          {translate"HappyX has additional useful routes - setup, middleware, notfound, onException, and staticDir"}
      else:
        tP:
          {translate"HappyX has additional helpful routes - middleware, notfound and static directories"}
      
      CodeBlockGuide(@[
        ("Nim", "nim", nimSsrAdditionalRoutes, cstring"nim_additional_routes", newPlayResult()),
        ("Python", "python", pySsrAdditionalRoutes, cstring"py_additional_routes", newPlayResult()),
        ("JavaScript", "javascript", jsSsrAdditionalRoutes, cstring"js_additional_routes", newPlayResult()),
        ("TypeScript", "typescript", tsSsrAdditionalRoutes, cstring"ts_additional_routes", newPlayResult()),
      ])
