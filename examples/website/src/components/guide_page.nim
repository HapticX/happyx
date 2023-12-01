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
        case currentGuidePage.val
        of "introduction":
          component Introduction
        of "getting_started":
          component GettingStarted
        of "happyx_app":
          component HappyxApp
        of "path_params":
          component PathParams
        of "spa_basics":
          component SpaBasics
        of "reactivity":
          component Reactivity
        of "ssr_basics":
          component SsrBasics
        of "tailwind_and_other":
          component TailwindAndOther
        of "route_decorators":
          component Decorators
        of "db_access":
          component DbIntro
        of "mongo_db":
          component MongoDB

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
