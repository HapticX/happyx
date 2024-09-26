# Import HappyX
import
  ../../../../src/happyx,
  ../ui/[colors, translations],
  ./[button]



proc setCurrentLanguage*(lang: string) =
  var language: cstring = lang
  languageSettings.set(lang)
  try:
    buildJs:
      localStorage["happyx_spoken_language"] = ~language
  except:
    discard
  enableRouting = true
  route(currentRoute)


# let style = buildHtml:
#   tStyle: """
#     .dropdown:hover .dropdown-items {
#       display: block;
#     }
#   """
# document.head.appendChild(style.children[0])


# Declare component
proc LanguageSpinner*(): TagRef =
  buildHtml:
    tDiv(class = "flex justify-end relative inline-block group"):
      tSvg(
        "viewBox" = "0 0 24 24",
        "fill" = "none",
        "xmlns" = "http://www.w3.org/2000/svg",
        class = "h-8 w-8 stroke-[{Orange}] dark:stroke-[{Yellow}] cursor-pointer"
      ):
        tPath("stroke-width" = "2", "d" = "M21 12C21 16.9706 16.9706 21 12 21C7.02944 21 3 16.9706 3 12C3 7.02944 7.02944 3 12 3C16.9706 3 21 7.02944 21 12Z")
        tPath("stroke-width" = "2", "stroke-linecap" = "round", "d" = "M12 3.05554C14.455 5.25282 16 8.44597 16 12C16 15.554 14.455 18.7471 12 20.9444")
        tPath("stroke-width" = "2", "stroke-linecap" = "round", "d" = "M12.0625 21C9.57126 18.8012 8 15.5841 8 12C8 8.41592 9.57126 5.19883 12.0625 3")
        tPath("stroke-width" = "2", "stroke-linecap" = "round", "stroke-linejoin" = "round", "d" = "M3 12H21")
      tDiv(
        class = "opacity-0 max-h-0 pointer-events-none group-hover:opacity-100 group-hover:max-h-64 group-hover:pointer-events-auto absolute w-fit flex flex-col overflow-hidden rounded-md mt-8 duration-300 transition-all"
      ):
        tButton(class = "w-full text-nowrap px-1 text-4xl lg:text-2xl xl:text-base md:px-4 xl:px-8 py-1 text-[{Background}] dark:text-[{BackgroundDark}] bg-[{Orange}] dark:bg-[{Yellow}] opacity-90 hover:opacity-80 active:opacity-70 duration-300"):
          "English"
          @click:
            setCurrentLanguage("en")
        tButton(class = "w-full text-nowrap px-1 text-4xl lg:text-2xl xl:text-base md:px-4 xl:px-8 py-1 text-[{Background}] dark:text-[{BackgroundDark}] bg-[{Orange}] dark:bg-[{Yellow}] opacity-90 hover:opacity-80 active:opacity-70 duration-300"):
          "Français"
          @click:
            setCurrentLanguage("fr")
        tButton(class = "w-full text-nowrap px-1 text-4xl lg:text-2xl xl:text-base md:px-4 xl:px-8 py-1 text-[{Background}] dark:text-[{BackgroundDark}] bg-[{Orange}] dark:bg-[{Yellow}] opacity-90 hover:opacity-80 active:opacity-70 duration-300"):
          "日本語"
          @click:
            setCurrentLanguage("ja")
        tButton(class = "w-full text-nowrap px-1 text-4xl lg:text-2xl xl:text-base md:px-4 xl:px-8 py-1 text-[{Background}] dark:text-[{BackgroundDark}] bg-[{Orange}] dark:bg-[{Yellow}] opacity-90 hover:opacity-80 active:opacity-70 duration-300"):
          "中文"
          @click:
            setCurrentLanguage("zh")
        tButton(class = "w-full text-nowrap px-1 text-4xl lg:text-2xl xl:text-base md:px-4 xl:px-8 py-1 text-[{Background}] dark:text-[{BackgroundDark}] bg-[{Orange}] dark:bg-[{Yellow}] opacity-90 hover:opacity-80 active:opacity-70 duration-300"):
          "한국어"
          @click:
            setCurrentLanguage("ko")
        tButton(class = "w-full text-nowrap px-1 text-4xl lg:text-2xl xl:text-base md:px-4 xl:px-8 py-1 text-[{Background}] dark:text-[{BackgroundDark}] bg-[{Orange}] dark:bg-[{Yellow}] opacity-90 hover:opacity-80 active:opacity-70 duration-300"):
          "Русский"
          @click:
            setCurrentLanguage("ru")
