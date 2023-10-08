# Import HappyX
import
  ../../../../src/happyx,
  ../ui/[colors, code, play_states, translations],
  ../components/[
    code_block_guide, code_block, code_block_slider
  ]


component SsrBasics:
  `template`:
    tDiv(class = "flex flex-col px-8 py-2 backdrop-blur-sm xl:h-fit gap-4"):
      tH1: {translate"Server-side Applications Basics 🖥"}

      tP: {translate"This section will provide you with an overview of the core features and capabilities of SSR within HappyX web framework. SSR is a powerful technique that allows you to render web pages on the server-side before sending them to the client, resulting in improved performance and SEO optimization."}

      tP: {translate"HappyX server-side allows to use it from Nim, Python and NodeJS!"}

      if currentLanguage.val in ["Nim", "Python", "TypeScript", "JavaScript"]:
        tP: {translate"Minimal example in any supported language seems like that:"}
        
        component CodeBlockGuide(@[
          ("Nim", "nim", nimSsrHelloWorldExample, cstring"nim_import_ssr", newPlayResult()),
          ("Python", "python", pythonHelloWorldExample, cstring"py_import", newPlayResult()),
          ("JavaScript", "javascript", jsHelloWorldExample, cstring"js_import", newPlayResult()),
          ("TypeScript", "typescript", tsHelloWorldExample, cstring"ts_import", newPlayResult()),
        ])
      