import
  ../../../../src/happyx,
  ../path_params,
  ../components/[header, smart_card, card, section, code_block, about_section, drawer],
  ../ui/colors



mount RoadMap:
  "/":
    tDiv(class = "flex flex-col min-h-screen w-full bg-[{Background}] dark:bg-[{BackgroundDark}] text-[{Foreground}] dark:text-[{ForegroundDark}]"):
      # Drawer
      component drawer_comp
      # Header
      tDiv(class = "w-full sticky top-0 z-20"):
        component Header(drawer = drawer_comp)
      tDiv(class = "flex flex-col w-full h-full items-center gap-8 px-4 py-8"):
        tP(class = "text-6xl lg:text-4xl xl:text-3xl font-bold"):
          "HappyX RoadMap 🌎"
        
        tP(class = "text-3xl lg:text-2xl xl:text-xl font-semibold w-3/4 lg:w-2/3 xl:w-1/2"):
          "HappyX goals is development speed ⚡, efficiency 🎴 and speed 🔥"
        
        tDiv(class = "w-full grid grid-cols-2 lg:w-2/3 xl:w-1/2 xl:grid-cols-3 gap-4 lg:gap-8 xl:gap-12"):
          # v1.0.0
          component Card():
            tDiv(class = "w-full flex flex-col items-center gap-2 p-4 lg:p-2 xl:p-0"):
              tP(class = "text-4xl lg:text-2xl xl:text-lg font-semibold"):
                "v1.0.0"
              tP(class = "w-full text-2xl lg:text-lg xl:text-base"):
                "General features 🛠"
                tUl(class = "list-disc"):
                  tLi: "SPA/SSR Support ⚡"
                  tLi: "Multiple HTTP Servers 👨‍🔬"
                  tLi: "Hot Code Reloading 🔥"
                  tLi: "CLI 📦"
          # v1.5.0
          component Card():
            tDiv(class = "w-full flex flex-col items-center gap-2 p-4 lg:p-2 xl:p-0"):
              tP(class = "text-4xl lg:text-2xl xl:text-lg font-semibold"):
                "v1.5.0"
              tP(class = "w-full text-2xl lg:text-lg xl:text-base"):
                "Framework improvement ⚡"
                tUl(class = "list-disc"):
                  tLi: "Additional HTTP Servers 👨‍🔬"
                  tLi: "Translatable Strings 🔥"
                  tLi: "Static Directories 📁"
          # v1.10.0
          component Card():
            tDiv(class = "w-full flex flex-col items-center gap-2 p-4 lg:p-2 xl:p-0"):
              tP(class = "text-4xl lg:text-2xl xl:text-lg font-semibold"):
                "v1.10.0"
              tP(class = "w-full text-2xl lg:text-lg xl:text-base"):
                "Components Update 🧩"
                tUl(class = "list-disc"):
                  tLi: "Inheritance 👶"
                  tLi: "Methods 📦"
                  tLi: "Constructors ⚙"
          # v1.15.0
          component Card():
            tDiv(class = "w-full flex flex-col items-center gap-2 p-4 lg:p-2 xl:p-0"):
              tP(class = "text-4xl lg:text-2xl xl:text-lg font-semibold"):
                "v1.15.0"
              tP(class = "w-full text-2xl lg:text-lg xl:text-base"):
                "Built-In UI Components 🎴"
                tUl(class = "list-disc"):
                  tLi: "Simple - Buttons, Inputs, etc ✨"
                  tLi: "Complex - TabView, GridView, etc 🍍"
          # v1.20.0
          component Card():
            tDiv(class = "w-full flex flex-col items-center gap-2 p-4 lg:p-2 xl:p-0"):
              tP(class = "text-4xl lg:text-2xl xl:text-lg font-semibold"):
                "v1.20.0"
              tP(class = "w-full text-2xl lg:text-lg xl:text-base"):
                "Documentation 📕"
                tUl(class = "list-disc"):
                  tLi: "Automatic RestAPI documentation 👨‍🔬"
                  tLi: "HappyX For Jester Programmers 🃏"
                  tLi: "HappyX For Karax Programmers 🐥"
          # v2.0.0
          component Card():
            tDiv(class = "w-full flex flex-col items-center gap-2 p-4 lg:p-2 xl:p-0"):
              tP(class = "text-4xl lg:text-2xl xl:text-lg font-semibold"):
                "v2.0.0"
              tP(class = "w-full text-2xl lg:text-lg xl:text-base"):
                "Language Bindings 🔌"
                tUl(class = "list-disc"):
                  tLi: "Python 🐍"
                  tLi: "JavaScript 🌐"
              tP(class = "w-full text-2xl lg:text-lg xl:text-base"):
                "Own Template Engine"
              tP(class = "w-full text-2xl lg:text-lg xl:text-base"):
                "Nim v2.0 Support"
