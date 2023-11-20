# Import HappyX
import
  ../../../../src/happyx,
  ../ui/[colors, translations],
  ../docs/docs,
  ./[button, drawer, sidebar, code_block_guide],
  unicode,
  json


component GuidePage:
  current: string = ""

  `template`:
    tDiv(
      class = "flex flex-col text-3xl lg:text-xl xl:text-base w-full h-full px-4 lg:px-12 xl:px-24 py-2 bg-[{BackgroundSecondary}] dark:bg-[{BackgroundSecondaryDark}] gap-8"
    ):
      tDiv(class = "flex flex-col gap-4"):

        if currentGuidePage == "introduction":
          component Introduction
        elif currentGuidePage == "getting_started":
          component GettingStarted
        elif currentGuidePage == "happyx_app":
          component HappyxApp
        elif currentGuidePage == "path_params":
          component PathParams
        elif currentGuidePage == "spa_basics":
          component SpaBasics
        elif currentGuidePage == "reactivity":
          component Reactivity
        elif currentGuidePage == "ssr_basics":
          component SsrBasics
        elif currentGuidePage == "tailwind_and_other":
          component TailwindAndOther
        elif currentGuidePage == "route_decorators":
          component Decorators

      tDiv(class = "hidden xl:flex justify-between items-center w-full pb-8"):
        if guidePages[currentGuidePage]["prev"].getStr != "":
          component Button(
              action = proc() =
                route(fmt"""/guide/{guidePages[currentGuidePage]["prev"].getStr}""")
          ):
            {"👈 " & translate(guidePages[guidePages[currentGuidePage]["prev"].getStr]["title"].getStr)}
        else:
          tDiv(class = "w-1 h-1 p-1")
        if guidePages[currentGuidePage]["next"].getStr != "":
          component Button(
              action = proc() =
                route(fmt"""/guide/{guidePages[currentGuidePage]["next"].getStr}""")
          ):
            {translate(guidePages[guidePages[currentGuidePage]["next"].getStr]["title"].getStr) & " 👉"}
        else:
          tDiv(class = "w-1 h-1 p-1")
      tDiv(class = "flex xl:hidden justify-between items-center w-full pb-8"):
        if guidePages[currentGuidePage]["prev"].getStr != "":
          component Button(
              action = proc() =
                route(fmt"""/guide/{guidePages[currentGuidePage]["prev"].getStr}"""),
              flat = true
          ):
            {"👈 " & translate(guidePages[guidePages[currentGuidePage]["prev"].getStr]["title"].getStr)}
        else:
          tDiv(class = "w-1 h-1 p-1")
        if guidePages[currentGuidePage]["next"].getStr != "":
          component Button(
              action = proc() =
                route(fmt"""/guide/{guidePages[currentGuidePage]["next"].getStr}"""),
              flat = true
          ):
            {translate(guidePages[guidePages[currentGuidePage]["next"].getStr]["title"].getStr) & " 👉"}
        else:
          tDiv(class = "w-1 h-1 p-1")
