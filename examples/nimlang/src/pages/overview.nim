import
  ../../../../src/happyx,
  ../app_config,
  ../components/components,
  highlightjs


component Overview:
  choosed: int = 0
  data: seq[tuple[name, code: string]] = @[
    (name: "Simple Example", code: simpleExample),
    (name: "if-else, case-switch", code: ifElseSwitchCase),
    (name: "Basic Math", code: basicMath),
    (name: "String Operators", code: stringOperators),
    (name: "Comprehensions", code: comprehensions)
  ]
  html:
    tDiv(class = "flex flex-col bg-[{background}] pt-8 text-white justify-center items-center"):
      tDiv(class = "flex gap-4 flex-col gap-4 pb-6 px-4 w-full overflow-hidden lg:flex-row lg:w-4/5 2xl:!w-3/5"):
        # General
        tDiv(class = "flex flex-col gap-6 w-full lg:w-1/2"):
          tH1(class = "pb-4 text-[{yellow}] transition-all"):
            Heading(2):
              "Efficient, expressive, elegant"
          Heading(5):
            "Nim is a statically typed compiled systems programming language."
            "It combines successful concepts from mature languages like Python, Ada and Modula."
          # Install and Playground buttons
          tDiv(class = "flex justify-center items-center px-2 gap-6 text-lg rounded-lg"):
            # Install
            Button(
              action = proc() =
                route"/install"
            ):
              "Install Nim 2.0.2"
            # Try it online
            Button(
              action = proc() =
                window.open("https://play.nim-lang.org/", "_blank").focus(),
              false
            ):
              "Try it online"
          tDiv(class = "flex flex-col class font-medium"):
            Heading(3):
              "Efficient"
            tUl(class = "opacity-90 pl-4 list-inside text-lg font-normal flex flex-col gap-2"):
              tLi:
                "Nim generates native dependency-free executables, not dependent on a virtual machine, which are small and allow easy redistribution."
              tLi:
                "The Nim compiler and the generated executables support all major platforms like Windows, Linux, BSD and macOS."
              tLi:
                "Nim's memory management is deterministic and customizable with destructors and move semantics, inspired by C++ and Rust. It is well-suited for embedded, hard-realtime systems."
              tLi:
                "Modern concepts like zero-overhead iterators and compile-time evaluation of user-defined functions, in combination with the preference of value-based datatypes allocated on the stack, lead to extremely performant code."
              tLi:
                "Support for various backends: it compiles to C, C++, Objective-C or JavaScript so that Nim can be used for all backend and frontend needs."
          tDiv(class = "flex flex-col class font-medium"):
            Heading(3):
              "Expressive"
            tUl(class = "opacity-90 pl-4 list-inside text-lg font-normal flex flex-col gap-2"):
              tLi:
                "Nim is self-contained: the compiler and the standard library are implemented in Nim."
              tLi:
                "Nim has a powerful macro system which allows direct manipulation of the AST, offering nearly unlimited opportunities."
          tDiv(class = "flex flex-col class font-medium"):
            Heading(3):
              "Elegant"
            tUl(class = "opacity-90 pl-4 list-inside text-lg font-normal flex flex-col gap-2"):
              tLi:
                "Macros cannot change Nim's syntax because there is no need for it — the syntax is flexible enough."
              tLi:
                "Modern type system with local type inference, tuples, generics and sum types."
              tLi:
                "Statements are grouped by indentation but can span multiple lines."
          tStyle: """
            li::before {
              content: "» ";
              font-weight: bold;
              margin-right: 8px;
              color: #ffe953;
            }
          """
        # Code example
        tDiv(class = "flex flex-col w-full max-w-full lg:max-w-1/2 lg:w-1/2"):
          tButton(class = "w-full group text-black bg-[{gray}] rounded-t-sm rounded-b-sm focus:rounded-b-none relative w-fit flex justify-center items-center text-3xl lg:text-xl xl:text-2xl"):
            tP(class = "select-none cursor-pointer px-4 py-1"):
              {self.data.val[self.choosed.val].name}
              " [choose]"
            tDiv(class = "absolute w-full h-full flex justify-end items-center px-4"):
              tSvg(width = "16", height = "16", viewBox = "0 -4.5 20 20", xmlns = "http://www.w3.org/2000/svg"):
                tPath(
                  d = "M.292.366c-.39.405-.39 1.06 0 1.464l8.264 8.563c.78.81 2.047.81 2.827 0l8.325-8.625c.385-.4.39-1.048.01-1.454a.976.976 0 0 0-1.425-.011l-7.617 7.893a.975.975 0 0 1-1.414 0L1.705.366a.974.974 0 0 0-1.413 0",
                  fill = "#000",
                  "fill-rule" = "evenodd"
                )
            tDiv(class = "absolute w-full bg-[{gray}] overflow-hidden rounded-b-sm py-4 duration-300 scale-y-0 opacity-0 group-focus:scale-y-100 group-focus:opacity-100 group-focus:translate-y-1/2 mt-5"):
              for i in 0..<self.data.len:
                tDiv(class = "select-none px-4 cursor-pointer bg-black/0 hover:bg-black/10 active:bg-black/20 duration-300"):
                  {self.data.val[i].name}
                  @click:
                    self.choosed = i
          for i in 0..<self.data.len:
            if i == self.choosed:
              CodeBlock(self.data.val[i].code, "nim")
          tA(
            class = "py-2 w-full text-center hover:underscore text-[{yellow}]/80 hover:text-[{yellow}]/90 active:text-[{yellow}] duration-300 active",
            href = "http://rosettacode.org/wiki/Category:Nim"
          ):
            "More examples at RosettaCode…"
      # Latest blog
      tDiv(class = "flex flex-col items-center w-full bg-white text-black py-8"):
        Heading(2):
          "Recent articles"
        
  
  @updated:
    hljs.highlightAll()
