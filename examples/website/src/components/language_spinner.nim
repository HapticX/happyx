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


let style = buildHtml:
  tStyle: """
    .dropdown:hover .dropdown-items {
      display: block;
    }
  """
document.head.appendChild(style)


# Declare component
proc LanguageSpinner*(): TagRef =
  buildHtml:
    tDiv(class = "dropdown relative inline-block"):
      Button:
        {translate"🌏 Language"}
      tDiv(class = "dropdown-items absolute w-full hidden overflow-hidden rounded-md"):
        tButton(class = "w-full px-1 text-4xl lg:text-2xl xl:text-base md:px-4 xl:px-8 py-1 text-[{Background}] dark:text-[{BackgroundDark}] bg-[{Orange}] dark:bg-[{Yellow}] opacity-90 hover:opacity-80 active:opacity-70 duration-300"):
          "English"
          @click:
            setCurrentLanguage("en")
        tButton(class = "w-full px-1 text-4xl lg:text-2xl xl:text-base md:px-4 xl:px-8 py-1 text-[{Background}] dark:text-[{BackgroundDark}] bg-[{Orange}] dark:bg-[{Yellow}] opacity-90 hover:opacity-80 active:opacity-70 duration-300"):
          "Français"
          @click:
            setCurrentLanguage("fr")
        tButton(class = "w-full px-1 text-4xl lg:text-2xl xl:text-base md:px-4 xl:px-8 py-1 text-[{Background}] dark:text-[{BackgroundDark}] bg-[{Orange}] dark:bg-[{Yellow}] opacity-90 hover:opacity-80 active:opacity-70 duration-300"):
          "日本語"
          @click:
            setCurrentLanguage("ja")
        tButton(class = "w-full px-1 text-4xl lg:text-2xl xl:text-base md:px-4 xl:px-8 py-1 text-[{Background}] dark:text-[{BackgroundDark}] bg-[{Orange}] dark:bg-[{Yellow}] opacity-90 hover:opacity-80 active:opacity-70 duration-300"):
          "中文"
          @click:
            setCurrentLanguage("zh")
        tButton(class = "w-full px-1 text-4xl lg:text-2xl xl:text-base md:px-4 xl:px-8 py-1 text-[{Background}] dark:text-[{BackgroundDark}] bg-[{Orange}] dark:bg-[{Yellow}] opacity-90 hover:opacity-80 active:opacity-70 duration-300"):
          "한국어"
          @click:
            setCurrentLanguage("ko")
        tButton(class = "w-full px-1 text-4xl lg:text-2xl xl:text-base md:px-4 xl:px-8 py-1 text-[{Background}] dark:text-[{BackgroundDark}] bg-[{Orange}] dark:bg-[{Yellow}] opacity-90 hover:opacity-80 active:opacity-70 duration-300"):
          "Русский"
          @click:
            setCurrentLanguage("ru")
