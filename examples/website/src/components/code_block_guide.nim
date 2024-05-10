import
  ../../../../src/happyx,
  ../ui/[colors, play_states, translations],
  jsffi


var localStorage {.importc, nodecl.}: JsObject


var currentLanguage* = remember "Nim"

# Load saved current language
var savedLang: cstring = localStorage["happyx_programming_language"].to(cstring)
if savedLang.len != 0:
  currentLanguage.val = $savedLang


component LanguageChooser:
  lang: string
  alias: string = ""
  `template`:
    tDiv(
        class =
          if self.lang == currentLanguage or self.alias == currentLanguage:
            fmt"text-black px-4 lg:px-2 py-2 lg:py-1 bg-[#ffffff30] dark:bg-[#00000030] xl:py-0 select-none"
          else:
            fmt"text-black px-4 lg:px-2 py-2 lg:py-1 bg-[#ffffff10] dark:bg-[#00000010] hover:bg-[#ffffff20] dark:hover:bg-[#00000020] xl:py-0 select-none cursor-pointer duration-150"
    ):
      {self.lang}
      @click:
        if self.alias == "":
          if self.lang != currentLanguage:
            var lang: cstring = $(self.lang.val)
            localStorage["happyx_programming_language"] = lang
            currentLanguage.set(self.lang)
            route(currentRoute)
        elif self.alias != currentLanguage:
          var lang: cstring = $(self.alias.val)
          localStorage["happyx_programming_language"] = lang
          currentLanguage.set(self.alias)
          route(currentRoute)


component CodeBlockGuide:
  sources: seq[tuple[title, lang, src: string, id: cstring, playResult: PlayResult]] = @[]

  `template`:
    nim:
      var languages: seq[string] = @[]
      for i in 0..<self.sources.len:
        languages.add(self.sources.val[i].title)
    tPre(class = "relative"):
      tDiv(class = "flex relative ml-4 justify-center w-fit group rounded-t-md bg-[{BackgroundSecondary}] dark:bg-[{BackgroundSecondaryDark}]"):
        tDiv(class = "px-4 rounded-t-md bg-[#0d1117] cursor-pointer select-none text-2xl lg:text-xl xl:text-base"):
          {currentLanguage}
          {translate" [change]"}
        tDiv(class = "absolute scale-0 drop-shadow-xl pb-12 lg:pb-2 -z-10 pt-1 rounded-md pointer-events-none -translate-y-full lg:-translate-y-1/3 opacity-0 group-hover:opacity-100 group-hover:scale-100 group-hover:-translate-y-full group-hover:pointer-events-auto group-hover:z-10 duration-300"):
          tDiv(class = "bg-[{Orange}] dark:bg-[{Yellow}] overflow-hidden py-6 lg:py-4 xl:py-2"):
            if haslanguage(self.CodeBlockGuide, "Nim"):
              LanguageChooser("Nim")
            if haslanguage(self.CodeBlockGuide, "Nim (SPA)"):
              LanguageChooser("Nim (SPA)")
            if haslanguage(self.CodeBlockGuide, "Python"):
              LanguageChooser("Python")
            if haslanguage(self.CodeBlockGuide, "JavaScript"):
              LanguageChooser("JavaScript")
            if haslanguage(self.CodeBlockGuide, "TypeScript"):
              LanguageChooser("TypeScript")
            if haslanguage(self.CodeBlockGuide, "Java"):
              LanguageChooser("Java")
            if haslanguage(self.CodeBlockGuide, "Kotlin"):
              LanguageChooser("Kotlin")
            tDiv(class = "flex justify-center text-[{Orange}] dark:text-[{Yellow}] absolute bottom-0 inset-x-0 -translate-y-2/3 lg:translate-y-1/3 cursor-pointer"):
              "▼"
      for i in 0..<self.sources.len:
        nim:
          let source = self.sources.val[i]
        if currentLanguage == source.title:
          tCode(
            id = "{source.id}",
            language = source.lang,
            class =
              if source.playResult.states.len > 0:
                fmt"rounded-t-md text-3xl lg:text-lg xl:text-base language-{source.lang}"
              else:
                fmt"rounded-md text-3xl lg:text-lg xl:text-base language-{source.lang}"
          ):
            {source.src}
          tDiv(class = "absolute right-2 top-20 lg:top-12 xl:top-8"):
            tSvg(
              viewBox = "0 0 24 24",
              class = "w-10 lg:w-6 h-10 lg:h-6 fill-white hover:fill-gray-200 active:fill-gray-400 transition-all cursor-pointer select-none"
            ):
              tPath("fill-rule"="evenodd", "clip-rule"="evenodd", d="M21 8C21 6.34315 19.6569 5 18 5H10C8.34315 5 7 6.34315 7 8V20C7 21.6569 8.34315 23 10 23H18C19.6569 23 21 21.6569 21 20V8ZM19 8C19 7.44772 18.5523 7 18 7H10C9.44772 7 9 7.44772 9 8V20C9 20.5523 9.44772 21 10 21H18C18.5523 21 19 20.5523 19 20V8Z")
              tPath(d="M6 3H16C16.5523 3 17 2.55228 17 2C17 1.44772 16.5523 1 16 1H6C4.34315 1 3 2.34315 3 4V18C3 18.5523 3.44772 19 4 19C4.55228 19 5 18.5523 5 18V4C5 3.44772 5.44772 3 6 3Z")
              @click:
                var data: cstring = source.src
                {.emit: "navigator.clipboard.writeText(`data`);".}
          if source.playResult.states.len > 0:
            tDiv(class = "flex bg-[#0d1117] rounded-b-md"):
              tDiv(
                id = "{source.id}play_button",
                class = "flex gap-2 justify-center items-center select-none cursor-pointer px-4 pb-2"
              ):
                tSvg(class = "w-16 lg:w-8 h-16 lg:h-8 fill-white", viewBox = "0 0 24 24", fill = "none"):
                  tPath(
                    "fill-rule" = "evenodd",
                    "clip-rule" = "evenodd",
                    d = "M2 12C2 6.47715 6.47715 2 12 2C17.5228 2 22 6.47715 22 12C22 17.5228 17.5228 22 12 22C6.47715 22 2 17.5228 2 12ZM15.5963 10.3318C16.8872 11.0694 16.8872 12.9307 15.5963 13.6683L11.154 16.2068C9.9715 16.8825 8.5002 16.0287 8.5002 14.6667L8.5002 9.33339C8.5002 7.97146 9.9715 7.11762 11.154 7.79333L15.5963 10.3318Z"
                  )
                @click:
                  let
                    source = self.CodeBlockGuide.sources.val[i]
                    playButton = document.getElementById(fmt"{source.id}play_button{self.uniqCompId}")
                    playResult = document.getElementById(fmt"{source.id}play_result{self.uniqCompId}")
                  var idx = 0

                  playButton.classList.add("hidden")
                  playResult.classList.remove("hidden")
                  playResult.innerHTML = ""
                  
                  var timeout = 0
                  for j in self.CodeBlockGuide.sources.val[i].playResult.states:
                    timeout += j.waitMs
                    withVariables j:
                      withTimeout timeout, t:
                        if j.text.len == 0 and j.html.len == 0:
                          playButton.classList.remove("hidden")
                          playResult.classList.add("hidden")
                        elif j.html.len != 0:
                          playResult.innerHTML &= j.html
                        else:
                          playResult.innerHTML &= fmt"""<pre><code id="{self.uniqCompId}{j.lang}{idx}" language="{j.lang}" class="language-{j.lang}" style="padding-top: 0 !important; padding-bottom: 0 !important;">{j.text}</code></pre>"""
                          let id: cstring = fmt"{self.uniqCompId}{j.lang}{idx}"
                          inc idx
                          buildJs:
                            let codeBlock = document.getElementById(~id)
                            hljs.highlightElement(codeBlock)
                        echo playResult.innerHTML
              tDiv(id = "{source.id}play_result", class = "w-full pb-4")
      if not haslanguage(self.CodeBlockGuide, currentLanguage.val):
        tCode(
          id = "unknown_lang",
          language = "shell",
          class = "rounded-md text-3xl lg:text-lg xl:text-base language-shell"
        ):
          "Unknown language - {currentLanguage}\n"
          "Choose one of these languages: \n"
          {languages.join(", ")}
      else:
        tDiv(id = "unknown_lang")
  
  @updated:
    for source in self.sources:
      highlight(self.CodeBlockGuide, source.id)
    highlight(self.CodeBlockGuide, cstring"unknown_lang")
  
  [methods]:
    proc highlight(id: cstring) =
      let id: cstring = $id & self.uniqCompId
      buildJs:
        let codeBlock = document.getElementById(~id)
        if codeBlock:
          hljs.highlightElement(codeBlock)
    
    proc hasLanguage(lang: string): bool =
      for source in self.sources:
        if source.title == lang:
          return true
      false
