# Import HappyX
import
  ../../../../src/happyx,
  ../ui/[colors, translations],
  ./[button, drawer],
  regex,
  unicode,
  macros,
  json,
  os


var
  currentGuidePage* = remember "introduction"
  guidePages* = %*{
    "introduction": {
      "title": "Introduction ✌",
      "prev": "",
      "next": "getting_started"
    },
    "getting_started": {
      "title": "Getting Started 💫",
      "prev": "introduction",
      "next": "happyx_app"
    },
    "happyx_app": {
      "title": "HappyX Application 🍍",
      "prev": "getting_started",
      "next": "path_params"
    },
    "path_params": {
      "title": "Path Params 🔌",
      "prev": "happyx_app",
      "next": "flags_list"
    },
    "flags_list": {
      "title": "Compilation flags 🔨",
      "prev": "path_params",
      "next": "tailwind_and_other"
    },
    "tailwind_and_other": {
      "title": "Tailwind And Other 🎴",
      "prev": "path_params",
      "next": "route_decorators"
    },
    "route_decorators": {
      "title": "Route Decorators 🔌",
      "prev": "tailwind_and_other",
      "next": "mounting"
    },
    "mounting": {
      "title": "Third-party routes 💫",
      "prev": "route_decorators",
      "next": "spa_basics"
    },
    "spa_basics": {
      "title": "Single-page Applications Basics 🎴",
      "prev": "route_decorators",
      "next": "spa_rendering"
    },
    "spa_rendering": {
      "title": "SPA Rendering 🧩",
      "prev": "spa_basics",
      "next": "reactivity"
    },
    "reactivity": {
      "title": "Reactivity ⚡",
      "prev": "spa_basics",
      "next": "components"
    },
    "components": {
      "title": "Components 🔥",
      "prev": "reactivity",
      "next": "func_components"
    },
    "func_components": {
      "title": "Functional components 🧪",
      "prev": "components",
      "next": "hpx_project_type"
    },
    "hpx_project_type": {
      "title": "HPX project type 👀",
      "prev": "func_components",
      "next": "ssr_basics"
    },
    "ssr_basics": {
      "title": "Server-side Applications Basics 🖥",
      "prev": "reactivity",
      "next": "db_access"
    },
    "db_access": {
      "title": "Database access 📦",
      "prev": "ssr_basics",
      "next": "sqlite"
    },
    "sqlite": {
      "title": "SQLite 📦",
      "prev": "db_access",
      "next": "postgres"
    },
    "postgres": {
      "title": "PostgreSQL 📦",
      "prev": "sqlite",
      "next": "mongo_db"
    },
    "mongo_db": {
      "title": "MongoDB 🍃",
      "prev": "postgres",
      "next": "ssr_docs"
    },
    "ssr_docs": {
      "title": "Swagger and Redoc in HappyX 📕",
      "prev": "mongo_db",
      "next": "liveviews"
    },
    "liveviews": {
      "title": "LiveViews 🔥",
      "prev": "ssr_docs",
      "next": "hpx_for_karax"
    },
    "hpx_for_karax": {
      "title": "Karax users 👑",
      "prev": "liveviews",
      "next": ""
    },
  }



proc toggleDrawerMobile*() =
  let
    drawerBack = document.getElementById("drawerBack")
    drawer = document.getElementById("drawer")
  drawerBack.classList.toggle("opacity-0")
  drawerBack.classList.toggle("opacity-100")
  drawerBack.classList.toggle("pointer-events-none")
  drawer.classList.toggle("translate-x-full")
  drawer.classList.toggle("translate-x-0")


proc SideBarTitle*(stmt: TagRef): TagRef =
  buildHtml:
    tDiv(class = "flex flex-col gap-8 lg:gap-4 xl:gap-2 text-7xl lg:text-2xl xl:text-xl font-bold select-none"):
      stmt


proc SideBarFolder*(id: string, text: string, isMobile: bool, stmt: TagRef): TagRef =
  buildHtml:
    tDiv(class = "flex flex-col gap-4 lg:gap-2 xl:gap-0 text-5xl lg:text-xl xl:text-lg font-bold cursor-pointer select-none pl-2"):
      tDiv:
        {translate(text)}
        @click:
          route(fmt"/guide/{id}")
          if isMobile:
            toggleDrawerMobile()
      stmt


proc SideBarItem*(id: string, isMobile: bool, stmt: TagRef): TagRef =
  buildHtml:
    tDiv(
      class =
        if currentGuidePage.val == id:
          fmt"pl-12 lg:pl-8 xl:pl-4 text-4xl opacity-90 lg:text-lg xl:text-base cursor-pointer select-none bg-[{Foreground}]/25 dark:bg-[{ForegroundDark}]/25 duration-300"
        else:
          fmt"pl-12 lg:pl-8 xl:pl-4 text-4xl opacity-60 hover:opacity-70 active:opacity-80 lg:text-lg xl:text-base cursor-pointer select-none bg-[{Foreground}]/0 dark:bg-[{ForegroundDark}]/0 hover:bg-[{Foreground}]/[.10] dark:hover:bg-[{ForegroundDark}]/[.10] active:bg-[{Foreground}]/[.20] dark:active:bg-[{ForegroundDark}]/[.20] duration-300"
    ):
      stmt
      @click:
        route(fmt"/guide/{id}")
        if isMobile:
          toggleDrawerMobile()


# Declare component
proc SideBar*(isMobile: bool = false): TagRef =
  buildHtml:
    tDiv(class =
        if isMobile:
          "flex-col xl:flex gap-12 lg:gap-8 xl:gap-4 px-2 h-full"
        else:
          "flex-col hidden xl:flex gap-12 lg:gap-8 xl:gap-4 px-2 pt-8 overflow-y-auto max-h-[95vh]"
    ):
      if not isMobile:
        tP(class = "text-5xl lg:text-3xl xl:text-2xl font-bold text-center w-max"):
          {translate"📕 Documentation"}
      tDiv(class = "flex flex-col justify-between gap-16 lg:gap-12 xl:gap-8"):
        tDiv(class = "flex flex-col pl-8 lg:pl-6 xl:pl-4 gap-8 lg:gap-4 xl:gap-2"):
          SideBarTitle:
            {translate"User Guide 📖"}

            SideBarFolder("introduction", "General 🍍", isMobile):
              SideBarItem("introduction", isMobile):
                {translate"Introduction ✌"}
              SideBarItem("getting_started", isMobile):
                {translate"Getting Started 💫"}

            SideBarFolder("happyx_app", "Basics 📖", isMobile):
              SideBarItem("happyx_app", isMobile):
                {translate"HappyX Application 🍍"}
              SideBarItem("path_params", isMobile):
                {translate"Path Params 🔌"}
              SideBarItem("flags_list", isMobile):
                {translate"Compilation flags 🔨"}

            SideBarFolder("tailwind_and_other", "Advanced 🧪", isMobile):
              SideBarItem("tailwind_and_other", isMobile):
                {translate"Tailwind And Other 🎴"}
              SideBarItem("route_decorators", isMobile):
                {translate"Route Decorators 🔌"}
              SideBarItem("mounting", isMobile):
                {translate"Third-party routes 💫"}

            SideBarFolder("spa_basics", "Single-page Applications 🎴", isMobile):
              SideBarItem("spa_basics", isMobile):
                {translate"Single-page Applications Basics 🎴"}
              SideBarItem("spa_rendering", isMobile):
                {translate"SPA Rendering 🧩"}
              SideBarItem("reactivity", isMobile):
                {translate"Reactivity ⚡"}
              SideBarItem("components", isMobile):
                {translate"Components 🔥"}
              SideBarItem("func_components", isMobile):
                {translate"Functional components 🧪"}
              SideBarItem("hpx_project_type", isMobile):
                {translate"HPX project type 👀"}

            SideBarFolder("ssr_basics", "Server-side Applications 🖥", isMobile):
              SideBarItem("ssr_basics", isMobile):
                {translate"Server-side Applications Basics 🖥"}
              SideBarItem("db_access", isMobile):
                {translate"Database access 📦"}
              SideBarItem("sqlite", isMobile):
                {translate"SQLite 📦"}
              SideBarItem("postgres", isMobile):
                {translate"PostgreSQL 📦"}
              SideBarItem("mongo_db", isMobile):
                {translate"MongoDB 🍃"}
              SideBarItem("ssr_docs", isMobile):
                {translate"Swagger and Redoc in HappyX 📕"}
              SideBarItem("liveviews", isMobile):
                "LiveViews 🔥"
            SideBarFolder("hpx_for_karax", "HappyX for ...", isMobile):
              SideBarItem("hpx_for_karax", isMobile):
                {translate"Karax users 👑"}
        tDiv(class = "flex"):
          Button(
            action = proc() =
              {.emit: """//js
              window.open('https://hapticx.github.io/happyx/happyx.html', '_blank').focus();
              """.},
            flat = true
          ):
            {translate"📕 API Reference"}
