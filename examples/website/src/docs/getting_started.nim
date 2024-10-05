# Import HappyX
import
  ../../../../src/happyx,
  ../ui/[colors, code, play_states, translations],
  ../components/[
    code_block_guide, code_block
  ]


proc GettingStarted*(): TagRef =
  buildHtml:
    tDiv(class = "flex flex-col px-8 py-2 xl:h-fit gap-4"):
      tH1: { translate"Getting Started 💫" }
      tP:
        { translate"Before you begin, please make sure you have"}
        if currentLanguage in ["Nim", "Nim (SPA)"]:
          tCode: tA(href = "https://nim-lang.org"):
            { translate"Nim programming language" }
          { translate" version 1.6.14 or higher, or " }
        elif currentLanguage == "Python":
          tCode: tA(href = "https://python.org"):
            { translate"Python programming language" }
          { translate" version 3.7 and above." }
        elif currentLanguage in ["JavaScript", "TypeScript"]:
          tCode: tA(href = "https://nodejs.org/en"):
            "NodeJS"
          { translate" version 16.13.0 and above." }
      
      tH2: { translate"Installing 📥" }
      tP: { translate"To install HappyX you can write this command" }
      CodeBlockGuide(@[
        ("Nim", "shell", "nimble install happyx@#head", cstring"nimble_install", newPlayResult()),
        ("Nim (SPA)", "shell", "nimble install happyx@#head", cstring"nimble_install", newPlayResult()),
        ("Python", "shell", "pip install happyx", cstring"pypi_install", newPlayResult()),
        ("JavaScript", "shell", "npm install happyx", cstring"npm_js_install", newPlayResult()),
        ("TypeScript", "shell", "npm install happyx", cstring"npm_ts_install", newPlayResult()),
      ])

      tP: { translate"Along with the library, you will also have the hpx CLI installed. With it, you can create HappyX projects and take advantage of hot code reloading. Use the command below for details." }
      CodeBlock("shell", "hpx help", "hpx_help")
      
      tH2: "Hello, World! 👋"

      tP:
        { translate("Let's create the first application. To do this, create a file $# and write the following code there:", "example.nim") }

      CodeBlockGuide(@[
        ("Nim", "nim", nimSsrHelloWorldExample, cstring"nim_ssr", newPlayResult()),
        ("Nim (SPA)", "nim", nimSpaHelloWorldExample, cstring"nim_ssr", newPlayResult()),
        ("Python", "python", pythonHelloWorldExample, cstring"py_hello_world", newPlayResult()),
        ("JavaScript", "javascript", jsHelloWorldExample, cstring"js_hello_world", newPlayResult()),
        ("TypeScript", "typescript", tsHelloWorldExample, cstring"ts_hello_world", newPlayResult()),
      ])

      tH3: {translate"Run App ▶"}

      if currentLanguage == "Nim (SPA)":
        tP:
          {translate"If you create Single-page application then you need "}
          tCode: "example.html"
          {translate"file:"}
        
        CodeBlock("html", htmlHelloWorldExample, "html_hello_world")

      CodeBlockGuide(@[
        ("Nim", "shell", "nim c -r example.nim", cstring"nim_ssr", playHelloWorld),
        ("Nim (SPA)", "shell", "nim js example.nim\nopen example.html", cstring"nim_ssr", playHelloWorldSPA),
        ("Python", "shell", "python example.py", cstring"py_hello_world", playHelloWorld),
        ("JavaScript", "shell", "node example.js", cstring"js_hello_world", playHelloWorld),
        ("TypeScript", "shell", "tsc && node example.js", cstring"ts_hello_world", playHelloWorld),
      ])

