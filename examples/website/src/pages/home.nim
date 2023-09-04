# Import HappyX
import
  ../../../../src/happyx,
  ../path_params,
  ../components/[header, smart_card, card, section, code_block, about_section, drawer, guide_page],
  ../ui/[colors, code]


var drawer_comp* = use:
  component Drawer


mount Home:
  "":
    # Component usage
    tDiv(class = "flex flex-col gap-2 bg-[{Background}] dark:bg-[{BackgroundDark}] text-[{Foreground}] dark:text-[{ForegroundDark}]"):
      tDiv(id = "cover", class = "flex flex-col gap-2 relative justify-center items-center h-screen"):
        tImg(src = "/happyx/public/cover_gradient.svg", class = "absolute h-screen w-screen object-cover pointer-events-none")
        tImg(src = "/happyx/public/nim_logo.svg", class = "z-10 pointer-events-none")
        tImg(src = "/happyx/public/HappyX.svg", class = "z-10 pointer-events-none")
        tImg(src = "/happyx/public/desc.svg", class = "z-10 pointer-events-none")
      # Drawer
      component drawer_comp
      # Main content
      tDiv(class = "flex flex-col gap-4"):
        tDiv(class = "sticky top-0 z-20"):
          component Header(drawer = drawer_comp)
        tDiv(class = "flex flex-col gap-16 items-center justify-center items-center w-full"):
          # Why HappyX is really required?
          component Section:
            tDiv(class = "flex flex-col xl:flex-row gap-8 lg:gap-4"):
              tDiv(class = "flex flex-col gap-4 lg:"):
                tDiv(class = "cursor-pointer hover:scale-110 hover:z-10 transition-all duration-500 flex flex-col rounded-xl px-6 py-4 drop-shadow-2xl bg-gradient-to-r from-[{Background}] to-[{BackgroundSecondary}] dark:from-[{BackgroundDark}] dark:to-[{BackgroundSecondaryDark}]"):
                  tP(class = "text-7xl lg:text-3xl xl:text-5xl font-semibold"):
                    "HappyX"
                  tP(class = "text-3xl lg:text-base"):
                    {translate("Powerful macro-oriented full-stack web framework")}
                  tP(class = "text-lg lg:text-xs font-thin"):
                    {translate("modern and powerful ready-to-product web framework")}
                tDiv(class = "cursor-pointer hover:scale-110 hover:z-10 transition-all duration-500 flex flex-col rounded-xl px-6 py-4 drop-shadow-2xl bg-gradient-to-r from-[{Background}] to-[{BackgroundSecondary}] dark:from-[{BackgroundDark}] dark:to-[{BackgroundSecondaryDark}]"):
                  tP(class = "text-5xl lg:text-xl xl:text-3xl font-semibold"):
                    {translate("metaprogramming")}
                  tP(class = "text-3xl lg:text-base"):
                    {translate("HappyX based on metaprogramming")}
                  tP(class = "text-3xl lg:text-base"):
                    {translate("so most part of code runs at compile-time.")}
                  tP(class = "text-lg lg:text-xs"):
                    {translate("This means that HappyX is REALLY fastest web framework")}
              tDiv(class = "cursor-pointer flex flex-col gap-4 lg:gap-2"):
                tDiv(class = "hover:scale-110 hover:z-10 transition-all duration-500 flex flex-col rounded-xl px-6 py-4 drop-shadow-2xl bg-gradient-to-r from-[{Background}] to-[{BackgroundSecondary}] dark:from-[{BackgroundDark}] dark:to-[{BackgroundSecondaryDark}]"):
                  tP(class = "text-5xl lg:text-xl xl:text-3xl font-semibold"):
                    {translate("full-stack")}
                  tP(class = "text-3xl lg:text-base"):
                    {translate("HappyX is full-stack web framework")}
                  tP(class = "text-3xl lg:text-base"):
                    {translate("so you shouldn't learn a new syntax/libraries/frameworks")}
                  tP(class = "text-3xl lg:text-base"):
                    {translate("to create modern and powerful web applications")}
                tDiv(class = "cursor-pointer hover:scale-110 hover:z-10 transition-all duration-500 flex flex-col rounded-xl px-6 py-4 drop-shadow-2xl bg-gradient-to-r from-[{Background}] to-[{BackgroundSecondary}] dark:from-[{BackgroundDark}] dark:to-[{BackgroundSecondaryDark}]"):
                  tP(class = "text-5xl lg:text-xl xl:text-3xl font-semibold"):
                    {translate("ready-to-product")}
                  tP(class = "text-3xl lg:text-base"):
                    {translate("HappyX is ready-to-product web framework")}
                  tP(class = "text-3xl lg:text-base"):
                    {translate("your company may use HappyX")}
          
          component CodeBlockSlider(
            data = @[
              (
                name: "SSR Example ⚡", description: "Server-side rendering application",
                text: ssrExample, language: "nim"
              ), (
                name: "SPA Example 🎴", description: "Single-page application",
                text: spaExample, language: "nim"
              ), (
                name: "FileResponse Example 📁", description: "Respond file from server to client",
                text: fileResponseExample, language: "nim"
              ), (
                name: "Path Params In SSR ⚙", description: "PathParams in server-side rendering",
                text: pathParamsSsrExample, language: "nim"
              ), (
                name: "Path Params In SPA ⚙", description: "PathParams in single-page application",
                text: pathParamsSpaExample, language: "nim"
              ),
            ]
          )
          
          # Features
          component Section:
            tP: {translate("One of the main features of HappyX is DSL ✌.")}
            tP: {translate("DSL supports:")}
            tDiv(class = "flex flex-col md:flex-row gap-6 py-8"):
              component Card(pathToImg = "/happyx/public/html5.svg"):
                {translate("Build HTML/CSS/JS")}
              component Card(pathToImg = "/happyx/public/setting.svg"):
                {translate("Path Params")}
              component Card(pathToImg = "/happyx/public/routing.svg"):
                {translate("Routing/Mounting")}

          # SPA
          component SmartCard:
            component CodeBlock(id = "spaCode", source = spaExample)
            tDiv(class = "w-48 xl:w-96 text-3xl lg:text-lg xl:text-base text-center subpixel-antialiased"):
              {translate("Make powerful full-stack apps with really same syntax ⚡")}
          
          # Macros
          component Section:
            tP: {translate("You can easily and effectively create powerful modern web apps ✌")}
            tP: {translate("You'll never have to learn new web frameworks again ✨")}
          
          # More info
          tDiv(class = "flex items-start justify-center w-full pb-8 gap-8"):
            component AboutSection(
              name = "HappyX For ... Programmers",
              data = @[
                ("FastAPI programmers", "https://github.com/HapticX/happyx/wiki/HappyX-for-FastAPI-Programmers"),
                ("Prologue programmers", "https://github.com/HapticX/happyx/wiki/HappyX-for-Prologue-Programmers"),
              ]
            )
            component AboutSection(
              name = "Contacts",
              data = @[
                ("Telegram Channel", "https://t.me/hapticx"),
                ("GitHub Discussions", "https://github.com/HapticX/happyx/discussions"),
                ("StackOverflow", "https://stackoverflow.com/search?q=%5Bnim-lang%5D+HappyX"),
              ]
            )
