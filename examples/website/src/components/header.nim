# Import HappyX
import
  std/algorithm,
  std/jsffi,
  ../../../../src/happyx,
  ../ui/[colors, translations],
  ./[button, drawer, sidebar, language_spinner],
  ../docs/docs


type
  SearchResult* = object
    header*: string
    fullText*: string
    lastText*: string
    path*: cstring
    pageName*: string
    isCode*: bool


var
  showSearchPopup = remember false
  pages = remember newTable[string, TagRef]()
  pagesIndexed = remember newSeq[JsObject]()
  searchResults = remember newSeq[SearchResult]()
  shouldIndex = true
  savedPages = pagesIndexed.val
  pageIndexName = cstring ("pagesIndexed" & HpxVersion)


{.emit: """//js
`savedPages` = JSON.parse(localStorage.getItem(`pageIndexName`)) || [];
console.log(`savedPages`);
if (`savedPages`.length !== 0) {
  `shouldIndex` = false;
  console.log("load saved indexed pages - ", `savedPages`.length);
}
""".}

if savedPages.len > 0:
  pagesIndexed.val = savedPages


proc indexPage*(pageName, path: cstring, page: Element) =
  let elements = page.querySelectorAll("p, h1, h2, h3, h4, h5, h6, code")
  var
    lastHeader: cstring = ""
    lastP: cstring = ""
  for element in elements:
    if element.nodeName in [cstring"P", cstring"CODE"]:
      let obj = newJsObject()
      if element.nodeName == cstring"P":
        lastP = element.textContent
      obj["text"] = element.textContent
      obj["lowerText"] = cstring ($element.textContent).toLower()
      obj["header"] = lastHeader
      obj["lastText"] = lastP
      obj["page"] = pageName
      obj["path"] = path
      obj["isCode"] = element.nodeName == cstring"CODE"
      pagesIndexed.val.add obj
    else:
      lastHeader = element.textContent
  page.innerHTML = "";


if shouldIndex:
  indexPage(cstring translate"Introduction ✌", "/guide/", initIntroduction("blabla").render())
  indexPage(cstring translate"Getting Started 💫", "/guide/getting_started", GettingStarted())
  indexPage(cstring translate"HappyX Application 🍍", "/guide/happyx_app", HappyxApp())
  indexPage(cstring translate"Path Params 🔌", "/guide/path_params", PathParams())
  indexPage(cstring translate"Compilation flags 🔨", "/guide/flags_list", FlagsList())
  indexPage(cstring translate"Tailwind And Other 🎴", "/guide/tailwind_and_other", TailwindAndOther())
  indexPage(cstring translate"Route Decorators 🔌", "/guide/route_decorators", Decorators())
  indexPage(cstring translate"Third-party routes 💫", "/guide/mounting", Mounting())
  indexPage(cstring translate"Single-page Applications Basics 🎴", "/guide/spa_basics", SpaBasics())
  indexPage(cstring translate"SPA Rendering 🧩", "/guide/spa_rendering", SpaRendering())
  indexPage(cstring translate"Reactivity ⚡", "/guide/reactivity", Reactivity())
  indexPage(cstring translate"Components 🔥", "/guide/components", initComponents("blablabla").render())
  indexPage(cstring translate"Functional components 🧪", "/guide/func_components", FuncComponents())
  indexPage(cstring translate"HPX project type 👀", "/guide/hpx_project_type", HpxProjectType())
  indexPage(cstring translate"Server-side Applications Basics 🖥", "/guide/ssr_basics", SsrBasics())
  indexPage(cstring translate"Websockets 🔌", "/guide/websockets", Websockets())
  indexPage(cstring translate"Database access 📦", "/guide/db_access", initDbIntro("db").render())
  indexPage(cstring translate"SQLite 📦", "/guide/sqlite", initSQLite("sqlite").render())
  indexPage(cstring translate"PostgreSQL 📦", "/guide/postgres", initPostgres("postgres").render())
  indexPage(cstring translate"MongoDB 🍃", "/guide/mongo_db", initMongoDB("mongo_db").render())
  indexPage(cstring translate"Swagger and Redoc in HappyX 📕", "/guide/ssr_docs", SsrDocs())
  indexPage(cstring translate"LiveViews 🔥", "/guide/liveviews", LiveViews())
  indexPage(cstring translate"HappyX for Karax users 👑", "/guide/hpx_for_karax", KaraxUsers())


  # Clear indexed components
  components.clear()
  createdComponentsList.setLen(0)
  currentComponentsList.setLen(0)

console.log("pages indexed: " & $pagesIndexed.val.len)
savedPages = pagesIndexed.val
{.emit: """//js
const obj = [];
for (let i of `savedPages`) {
  obj.push(i);
}
localStorage.setItem(`pageIndexName`, JSON.stringify(obj));
""".}


proc searchPages*(searchText: cstring) =
  var results = newSeq[SearchResult]()

  if searchText.len == 0:
    searchResults.set(results)
    return

  let lowerText = cstring ($searchText).toLower()

  for item in pagesIndexed.val:
    var index: cint = -1
    {.emit: """//js
    `index` = `item`.lowerText.indexOf(`lowerText`);
    """.}
    if index != -1:
      results.add SearchResult(
        header: $item["header"].to(cstring),
        fullText: $item["text"].to(cstring),
        lastText: $item["lastText"].to(cstring),
        pageName: $item["page"].to(cstring),
        path: item["path"].to(cstring),
        isCode: item["isCode"].to(bool),
      )
    if results.len >= 20:
      break
  searchResults.set(results)


{.emit: """//js
let lastSavedText = "";
const interval = setInterval(() => {
  let input = document.querySelector('#search-popup-input');
  if (!input)
    return;
  if (input.value === lastSavedText)
    return;
  `searchPages`(input.value);
  lastSavedText = input.value;
}, 250);
""".}


# Declare component
proc Header*(drawer: Drawer = nil): TagRef =
  buildHtml:
    tDiv(class = "fixed z-50 flex justify-center items-center left-0 right-0 top-0 bottom-0 pointer-events-none"):
      tDiv(
        class = "absolute z-10 left-0 right-0 bottom-0 top-0 backdrop-blur-sm bg-black/20 rounded-xl p-4 transition-all duration-300 " & (
          if showSearchPopup:
            "pointer-events-auto"
          else:
            "opacity-0 pointer-events-none"
        )
      ):
        @click:
          showSearchPopup.set(false)
      tDiv(
        class = fmt"flex flex-col gap-2 absolute z-20 drop-shadow-md rounded-xl p-8 min-w-[95vw] max-w-[95vw] xl:min-w-[50vw] xl:max-w-[50vw] bg-[{Background}] dark:bg-[{BackgroundDark}] transition-all duration-300 " & (
          if showSearchPopup:
            "pointer-events-auto"
          else:
            "pointer-events-none opacity-0 -translate-y-12 scale-90"
        ),
        id = "search-popup"
      ):
        tH2: { translate"Search" }
        tInput(
          class = "w-full outline-none border-none bg-[{BackgroundSecondary}] dark:bg-[{BackgroundSecondaryDark}] rounded-none py-2 px-4",
          placeholder = translate"Enter something",
          id = "search-popup-input"
        )
        tDiv(class = "flex flex-col gap-2 max-h-[70vh] xl:max-h-[50vh] overflow-y-auto"):
          for i, result in searchResults.val.pairs:
            tDiv(class = "flex flex-col border border-[{Foreground}]/25 dark:border-[{ForegroundDark}]/25 rounded-md p-2 cursor-pointer"):
              tH2(class = ""):
                {searchResults.val[i].pageName}
              if searchResults.val[i].isCode:
                if len(searchResults.val[i].lastText) != 0:
                  tP(search = "true"):
                    {searchResults.val[i].lastText}
                tPre(class = "bg-[{BackgroundSecondary}] dark:bg-[{BackgroundSecondaryDark}] p-4"):
                  tCode(search = "true"):
                    {searchResults.val[i].fullText}
              else:
                tP(search = "true"):
                  {searchResults.val[i].fullText}
              @click:
                route(searchResults.val[i].path)
                showSearchPopup.set(false)
                var text = cstring searchResults.val[i].fullText
                {.emit: """//js
                const tags = document.querySelectorAll("p, code");
                for (var i = 0; i < tags.length; i++) {
                  if (tags[i].textContent == `text` && tags[i].getAttribute("search") === null) {
                    window.scrollTo({
                      behavior: 'smooth',
                      top: tags[i].getBoundingClientRect().top - 128
                    });
                    break;
                  }
                }
                """.}
    tDiv(class = "flex justify-between items-center px-8 py-2 backdrop-blur-md dark:backdrop-blur-sm dark:bg-black dark:bg-opacity-20 h-32 xl:h-fit"):
      tDiv(class = "flex"):
        tImg(src = "/happyx/public/icon.webp", alt = "HappyX logo", class = "h-24 md:h-16 xl:h-12 cursor-pointer select-none")
        @click:
          route"/"
      # drawer here
      tDiv(class = "flex xl:hidden text-8xl font-bold select-none cursor-pointer"):
        "≡"
        @click:
          toggleDrawer()
      tDiv(class = "hidden xl:flex gap-4 items-center h-full"):  # buttons
        # Search
        tSvg(
          xmlns="http://www.w3.org/2000/svg",
          width="48",
          height="48",
          viewBox="0 0 24 24",
          class = "h-8 w-8 stroke-[{Orange}] dark:stroke-[{Yellow}] cursor-pointer"
        ):
          tPath(
            fill="none",
            stroke-linecap="round",
            stroke-linejoin="round",
            stroke-width="2",
            d="M17.5 17.5L22 22m-2-11a9 9 0 1 0-18 0a9 9 0 0 0 18 0",
          )
          @click:
            showSearchPopup.set(true)
            {.emit: """//js
            document.querySelector("#search-popup-input").value = "";
            document.querySelector("#search-popup-input").focus();
            """.}
        # Guide
        tSvg(
          "viewBox" = "0 0 24 24",
          "fill" = "none",
          "xmlns" = "http://www.w3.org/2000/svg",
          class = "h-8 w-8 stroke-[{Orange}] dark:stroke-[{Yellow}] cursor-pointer"
        ):
          tPath("stroke-width" = "2", "stroke-linecap" = "round", "stroke-linejoin" = "round", "d" = "M9 12H15")
          tPath("stroke-width" = "2", "stroke-linecap" = "round", "stroke-linejoin" = "round", "d" = "M9 15H15")
          tPath("stroke-width" = "2", "stroke-linejoin" = "round", "d" = "M17.8284 6.82843C18.4065 7.40649 18.6955 7.69552 18.8478 8.06306C19 8.4306 19 8.83935 19 9.65685L19 17C19 18.8856 19 19.8284 18.4142 20.4142C17.8284 21 16.8856 21 15 21H9C7.11438 21 6.17157 21 5.58579 20.4142C5 19.8284 5 18.8856 5 17L5 7C5 5.11438 5 4.17157 5.58579 3.58579C6.17157 3 7.11438 3 9 3H12.3431C13.1606 3 13.5694 3 13.9369 3.15224C14.3045 3.30448 14.5935 3.59351 15.1716 4.17157L17.8284 6.82843Z")
          @click:
            route"/guide/"
        # Sandbox
        # tSvg(
        #   "viewBox" = "0 0 24 24",
        #   "fill" = "none",
        #   "xmlns" = "http://www.w3.org/2000/svg",
        #   class = "h-8 w-8 stroke-[{Orange}] dark:stroke-[{Yellow}] cursor-pointer"
        # ):
        #   tPath("stroke-width" = "2", "d" = "M21 12C21 16.9706 16.9706 21 12 21C7.02944 21 3 16.9706 3 12C3 7.02944 7.02944 3 12 3C16.9706 3 21 7.02944 21 12Z")
        #   tPath("stroke-width" = "2", "stroke-linecap" = "round", "stroke-linejoin" = "round", "d" = "M10.9 8.8L10.6577 8.66152C10.1418 8.36676 9.5 8.73922 9.5 9.33333L9.5 14.6667C9.5 15.2608 10.1418 15.6332 10.6577 15.3385L10.9 15.2L15.1 12.8C15.719 12.4463 15.719 11.5537 15.1 11.2L10.9 8.8Z")
        #   @click:
        #     route"/sandbox/"
        # Sponsors
        tSvg(
          "viewBox" = "0 0 24 24",
          "fill" = "none",
          "xmlns" = "http://www.w3.org/2000/svg",
          class = "h-8 w-8 stroke-[{Orange}] dark:stroke-[{Yellow}] cursor-pointer"
        ):
          tPath("stroke-width" = "2", "stroke-linejoin" = "round", "d" = "M4.8057 5.70615C5.39093 4.87011 5.68354 4.45209 6.11769 4.22604C6.55184 4 7.0621 4 8.08262 4H12H15.9174C16.9379 4 17.4482 4 17.8823 4.22604C18.3165 4.45209 18.6091 4.87011 19.1943 5.70615L19.7915 6.55926C20.6144 7.73493 21.0259 8.32277 21.0064 8.98546C20.9869 9.64815 20.5415 10.2107 19.6507 11.3359L14.375 18V18C13.6417 18.9263 13.275 19.3895 12.8472 19.5895C12.3103 19.8406 11.6897 19.8406 11.1528 19.5895C10.725 19.3895 10.3583 18.9263 9.625 18V18L4.34927 11.3359C3.4585 10.2107 3.01312 9.64815 2.99359 8.98546C2.97407 8.32277 3.38555 7.73493 4.20852 6.55926L4.8057 5.70615Z")
          tPath("stroke-width" = "2", "stroke-linecap" = "round", "stroke-linejoin" = "round", "d" = "M9 7.5L8.5 8.25V8.25C8.20344 8.69484 8.23479 9.28176 8.57706 9.69247L10.5 12")
          @click:
            route"/sponsors/"
        # Roadmap
        tSvg(
          "viewBox" = "0 0 24 24",
          "fill" = "none",
          "xmlns" = "http://www.w3.org/2000/svg",
          class = "h-8 w-8 stroke-[{Orange}] dark:stroke-[{Yellow}] cursor-pointer"
        ):
          tPath("stroke-width" = "2", "stroke-linejoin" = "round", "d" = "M3 9C3 8.01858 3 7.52786 3.21115 7.10557C3.42229 6.68328 3.81486 6.38885 4.6 5.8L7 4V4C7.69964 3.47527 8.04946 3.2129 8.43022 3.11365C8.79466 3.01866 9.17851 3.02849 9.53761 3.14203C9.91278 3.26065 10.2487 3.54059 10.9206 4.10046L12.5699 5.47491C13.736 6.44667 14.3191 6.93255 15.0141 6.95036C15.7091 6.96817 16.3163 6.51279 17.5306 5.60203L18 5.25V5.25C19.2361 4.32295 21 5.20492 21 6.75V14V15C21 15.9814 21 16.4721 20.7889 16.8944C20.5777 17.3167 20.1851 17.6111 19.4 18.2L17 20V20C16.3004 20.5247 15.9505 20.7871 15.5698 20.8863C15.2053 20.9813 14.8215 20.9715 14.4624 20.858C14.0872 20.7394 13.7513 20.4594 13.0794 19.8995L10.9206 18.1005C10.2487 17.5406 9.91278 17.2606 9.53761 17.142C9.17851 17.0285 8.79466 17.0187 8.43022 17.1137C8.04946 17.2129 7.69964 17.4753 7 18V18V18C6.3181 18.5114 5.97715 18.7671 5.7171 18.867C4.61978 19.2885 3.39734 18.6773 3.07612 17.5465C3 17.2786 3 16.8524 3 16V10V9Z")
          tPath("stroke-width" = "2", "stroke-linecap" = "round", "stroke-linejoin" = "round", "d" = "M15 7.22924V20.5")
          tPath("stroke-width" = "2", "stroke-linecap" = "round", "stroke-linejoin" = "round", "d" = "M9 3.5V16.7083")
          @click:
            route"/roadmap/"
        LanguageSpinner()
        # GitHub
        tSvg(
          "viewBox" = "0 0 24 24",
          "fill" = "none",
          "xmlns" = "http://www.w3.org/2000/svg",
          class = "h-8 w-8 stroke-[{Orange}] dark:stroke-[{Yellow}] cursor-pointer"
        ):
          tPath("stroke-width" = "2", "stroke-linecap" = "round", "stroke-linejoin" = "round", "d" = "M9.29183 21V18.4407L9.3255 16.6219C9.36595 16.0561 9.58639 15.5228 9.94907 15.11C9.95438 15.1039 9.95972 15.0979 9.9651 15.0919C9.9791 15.0763 9.96988 15.0511 9.94907 15.0485V15.0485C7.52554 14.746 5.0005 13.7227 5.0005 9.26749C4.9847 8.17021 5.3427 7.10648 6.00437 6.27215C6.02752 6.24297 6.05103 6.21406 6.07492 6.18545V6.18545C6.10601 6.1482 6.11618 6.09772 6.10194 6.05134C6.10107 6.04853 6.10021 6.04571 6.09935 6.04289C6.0832 5.9899 6.06804 5.93666 6.05388 5.88321C5.81065 4.96474 5.86295 3.98363 6.20527 3.09818C6.20779 3.09164 6.21034 3.08511 6.2129 3.07858C6.22568 3.04599 6.25251 3.02108 6.28698 3.01493V3.01493C6.50189 2.97661 7.37036 2.92534 9.03298 4.07346C9.08473 4.10919 9.13724 4.14609 9.19053 4.18418V4.18418C9.22901 4.21168 9.27794 4.22011 9.32344 4.20716C9.32487 4.20675 9.32631 4.20634 9.32774 4.20593C9.41699 4.18056 9.50648 4.15649 9.59617 4.1337C11.1766 3.73226 12.8234 3.73226 14.4038 4.1337C14.4889 4.1553 14.5737 4.17807 14.6584 4.20199C14.6602 4.20252 14.6621 4.20304 14.6639 4.20356C14.7174 4.21872 14.7749 4.20882 14.8202 4.17653V4.17653C14.8698 4.14114 14.9187 4.10679 14.967 4.07346C16.6257 2.92776 17.4894 2.9764 17.7053 3.01469V3.01469C17.7404 3.02092 17.7678 3.04628 17.781 3.07946C17.7827 3.08373 17.7843 3.08799 17.786 3.09226C18.1341 3.97811 18.1894 4.96214 17.946 5.88321C17.9315 5.93811 17.9159 5.9928 17.8993 6.04723V6.04723C17.8843 6.09618 17.8951 6.14942 17.9278 6.18875C17.9289 6.18998 17.9299 6.19121 17.9309 6.19245C17.9528 6.21877 17.9744 6.24534 17.9956 6.27215C18.6573 7.10648 19.0153 8.17021 18.9995 9.26749C18.9995 13.747 16.4565 14.7435 14.0214 15.015V15.015C14.0073 15.0165 14.001 15.0334 14.0105 15.0439C14.0141 15.0479 14.0178 15.0519 14.0214 15.0559C14.2671 15.3296 14.4577 15.6544 14.5811 16.0103C14.7101 16.3824 14.7626 16.7797 14.7351 17.1754V21")
          tPath("stroke-width" = "2", "stroke-linecap" = "round", "stroke-linejoin" = "round", "d" = "M4 17C4.36915 17.0523 4.72159 17.1883 5.03065 17.3975C5.3397 17.6068 5.59726 17.8838 5.7838 18.2078C5.94231 18.4962 6.15601 18.7504 6.41264 18.9557C6.66927 19.161 6.96379 19.3135 7.27929 19.4043C7.59478 19.4952 7.92504 19.5226 8.25112 19.485C8.5772 19.4475 8.89268 19.3457 9.17946 19.1855")
          @click:
            {.emit:"""//js
            window.open('https://github.com/HapticX/happyx', '_blank').focus();
            """.}
