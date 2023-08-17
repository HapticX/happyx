import
  ../../../../src/happyx,
  ../path_params,
  ../components/[header, smart_card, card, section, code_block, about_section, drawer],
  ../ui/colors



mount LanguageBinds:
  "/":
    tDiv(class = "flex flex-col min-h-screen w-full bg-[{Background}] dark:bg-[{BackgroundDark}] text-[{Foreground}] dark:text-[{ForegroundDark}]"):
      # Drawer
      component drawer_comp
      # Header
      tDiv(class = "w-full sticky top-0 z-20"):
        component Header(drawer = drawer_comp)
      tDiv(class = "flex flex-col w-full h-full items-center gap-8 px-4 py-8"):
        tP(class = "text-6xl lg:text-4xl xl:text-3xl font-bold"):
          "HappyX Language Bindings 💻"
