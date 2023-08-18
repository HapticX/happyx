# Import HappyX
import
  ../../../../src/happyx,
  ../ui/colors,
  ../ui/code,
  ../ui/play_states,
  ../components/[
    code_block_guide, code_block
  ]


component GettingStarted:
  `template`:
    tDiv(class = "flex flex-col px-8 py-2 backdrop-blur-sm xl:h-fit gap-4"):
      tH1: "Getting Started 💫"
      tP:
        "Before you begin, please make sure you have"
        tCode: tA(href = "https://nim-lang.org"):
          "Nim programming language"
        " version 1.6.14 or higher installed, or "
        tCode: tA(href = "https://python.org"):
          "Python programming language"
        " version 3.10 and above."
      
      tH2: "Install 📥"
      tP: "To install HappyX you can write this command"

      component CodeBlockGuide(@[
        ("Nim", "shell", "nimble install happyx@#head", cstring"nimble_install", newPlayResult()),
        ("Nim (SPA)", "shell", "nimble install happyx@#head", cstring"nimble_install", newPlayResult()),
        ("Python", "shell", "pip install happyx", cstring"pypi_install", newPlayResult()),
      ])
      
      tH2: "Hello, World! 👋"

      tP:
        "There is our first application. I show you "
        tSpan(class = "text-green-800 dark:text-green-400"):
          "\"Hello, world!\""
        " example."

      component CodeBlockGuide(@[
        ("Nim", "nim", nimSsrHelloWorldExample, cstring"nim_ssr", newPlayResult()),
        ("Nim (SPA)", "nim", nimSpaHelloWorldExample, cstring"nim_ssr", newPlayResult()),
        ("Python", "python", pythonHelloWorldExample, cstring"py_hello_world", newPlayResult()),
      ])

      tH3: "Run App ▶"

      if currentLanguage == "Nim (SPA)":
        tP:
          "If you create Single-page application then you need "
          tCode: "example.html"
          "file:"
        
        component CodeBlock("html", htmlHelloWorldExample, "html_hello_world")

      component CodeBlockGuide(@[
        ("Nim", "shell", "nim c -r example.nim", cstring"nim_ssr", playHelloWorld),
        ("Nim (SPA)", "shell", "nim js example.nim\nopen example.html", cstring"nim_ssr", playHelloWorldSPA),
        ("Python", "shell", "python example.py", cstring"py_hello_world", playHelloWorld),
      ])

