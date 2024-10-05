# Import HappyX
import
  ../../../../src/happyx,
  ../ui/[colors, translations],
  ../docs/docs,
  ./[button, drawer, sidebar, code_block_guide, icons],
  std/unicode,
  std/json


component GuidePage:
  current: string = ""

  html:
    tDiv(
      class = "flex flex-col text-3xl lg:text-xl xl:text-base w-full 2xl:w-3/4 h-full px-4 lg:px-12 xl:px-16 py-2 bg-[{BackgroundSecondary}] dark:bg-[{BackgroundSecondaryDark}] gap-8"
    ):
      tDiv(id = nu"guide", class = "flex flex-col gap-4"):
        case currentGuidePage.val
        of "introduction":
          Introduction
        of "getting_started":
          GettingStarted
        of "happyx_app":
          HappyxApp
        of "path_params":
          PathParams
        of "spa_basics":
          SpaBasics
        of "spa_rendering":
          SpaRendering
        of "reactivity":
          Reactivity
        of "components":
          Components
        of "func_components":
          FuncComponents
        of "ssr_basics":
          SsrBasics
        of "tailwind_and_other":
          TailwindAndOther
        of "route_decorators":
          Decorators
        of "db_access":
          DbIntro
        of "mongo_db":
          MongoDB
        of "sqlite":
          SQLite
        of "postgres":
          Postgres
        of "ssr_docs":
          SsrDocs
        of "mounting":
          Mounting
        of "hpx_for_karax":
          KaraxUsers
        of "liveviews":
          LiveViews
        of "flags_list":
          FlagsList
        of "hpx_project_type":
          HpxProjectType

      tDiv(class = "hidden xl:flex justify-between items-center w-full pb-8"):
        if guidePages[currentGuidePage]["prev"].getStr != "":
          tDiv(class = "flex items-center justify-center gap-1 select-none cursor-pointer"):
            ArrowRight(fmt"w-8 h-8 stroke-[{Orange}] dark:stroke-[{Yellow}] rotate-180")
            { translate(guidePages[guidePages[currentGuidePage]["prev"].getStr]["title"].getStr) }
            @click:
              route(fmt"""/guide/{guidePages[currentGuidePage]["prev"].getStr}""")
        else:
          tDiv(class = "w-1 h-1 p-1")
        if guidePages[currentGuidePage]["next"].getStr != "":
          tDiv(class = "flex items-center justify-center gap-1 select-none cursor-pointer"):
            { translate(guidePages[guidePages[currentGuidePage]["next"].getStr]["title"].getStr) }
            ArrowRight(fmt"w-8 h-8 stroke-[{Orange}] dark:stroke-[{Yellow}]")
            @click:
              route(fmt"""/guide/{guidePages[currentGuidePage]["next"].getStr}""")
        else:
          tDiv(class = "w-1 h-1 p-1")
      tDiv(class = "flex xl:hidden justify-between items-center w-full pb-8"):
        if guidePages[currentGuidePage]["prev"].getStr != "":
          tDiv(class = "flex items-center justify-center gap-1 select-none cursor-pointer"):
            ArrowRight(fmt"w-10 h-10 stroke-[{Orange}] dark:stroke-[{Yellow}] rotate-180")
            { translate(guidePages[guidePages[currentGuidePage]["prev"].getStr]["title"].getStr) }
            @click:
              route(fmt"""/guide/{guidePages[currentGuidePage]["prev"].getStr}""")
        else:
          tDiv(class = "w-1 h-1 p-1")
        if guidePages[currentGuidePage]["next"].getStr != "":
          tDiv(class = "flex items-center justify-center gap-1 select-none cursor-pointer"):
            { translate(guidePages[guidePages[currentGuidePage]["next"].getStr]["title"].getStr) }
            ArrowRight(fmt"w-10 h-10 stroke-[{Orange}] dark:stroke-[{Yellow}]")
            @click:
              route(fmt"""/guide/{guidePages[currentGuidePage]["next"].getStr}""")
        else:
          tDiv(class = "w-1 h-1 p-1")
    tDiv(id = nu"navigation", class = "hidden 2xl:flex 2xl:w-1/5 pl-8 fixed right-0")
  
  @updated:
    let headers = document.querySelector("#guide").querySelectorAll("h1, h2, h3, h4, h5, h6")
    let navigation = document.querySelector("#navigation")
    let items = buildHtml:
      tDiv(class = "flex flex-col gap-2")
    var index = 0
    for i in headers:
      let item = buildHtml:
        tDiv(class = "border-l border-white cursor-pointer pl-2 transition-all duration-150"):
          {i.textContent}
      {.emit: """//js
      ((i) => {
        `item`.children[0].addEventListener('click', e => {
          window.scrollTo({
            top: i.getBoundingClientRect().top + window.pageYOffset - 100,
            behavior: "smooth"
          });
        });
      })(`i`)
      """.}
      i.classList.add(cstring(fmt"header-{index}{index+1}"))
      items.children[0].appendChild(item.children[0])
      inc index
    navigation.appendChild(items.children[0])
    {.emit: """//js
    function updateHeaders() {
      if (!document.querySelector("#guide")) {
        return;
      }
      const headers = document.querySelector("#guide").querySelectorAll("h1, h2, h3, h4, h5, h6");
      const navigation = document.querySelector("#navigation").children[0];
      let i = 0;
      headers.forEach(h => {
        if (window.pageYOffset <= h.getBoundingClientRect().top + window.pageYOffset - 65) {
          navigation.children[i].classList.remove("opacity-50");
          navigation.children[i].classList.add("opacity-70");
        } else {
          navigation.children[i].classList.add("opacity-50");
          navigation.children[i].classList.remove("opacity-70");
        }
        i++;
      });
      i = 0
      for (let e of navigation.children) {
        if (!e.classList.contains("opacity-50")) break;
        i++;
      }
      if (i < navigation.children.length) {
        navigation.children[i].classList.remove("opacity-70");
        navigation.children[i].classList.add("opacity-100");
      }
    }
    window.onscroll = updateHeaders;
    updateHeaders();
    """.}
