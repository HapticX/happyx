import
  ../../../../src/happyx,
  ../ui/[colors, play_states]


var currentLanguage* = remember "Nim"

# Load saved current language
var savedLang: cstring
buildJs:
  ~savedLang = localStorage["happyx_programming_language"]
  echo ~savedLang
if savedLang.len != 0:
  currentLanguage.val = $savedLang


component LanguageChooser:
  lang: string
  alias: string = ""
  `template`:
    tDiv(
        class =
          if self.lang == currentLanguage or self.alias == currentLanguage:
            fmt"px-8 lg:px-4 xl:px-2 py-2 lg:py-1 xl:py-0 bg-[{Foreground}40] dark:bg-[{ForegroundDark}40] select-none"
          else:
            fmt"px-8 lg:px-4 xl:px-2 py-2 lg:py-1 xl:py-0 bg-[{Foreground}20] dark:bg-[{ForegroundDark}20] select-none cursor-pointer"
    ):
      {self.lang}
      @click:
        if self.alias == "":
          if self.lang != currentLanguage:
            var lang: cstring = $(self.LanguageChooser.lang.val)
            buildJs:
              localStorage["happyx_programming_language"] = ~lang
            currentLanguage.set(self.lang)
        elif self.alias != currentLanguage:
          var lang: cstring = $(self.LanguageChooser.alias.val)
          buildJs:
            localStorage["happyx_programming_language"] = ~lang
          currentLanguage.set(self.alias)


component CodeBlockGuide:
  sources: seq[tuple[title, lang, src: string, id: cstring, playResult: PlayResult]] = @[]

  `template`:
    tPre(class = "relative"):
      tDiv(class = "flex rounded-t-md divide-x divide-x-2 divide-[{Foreground}75] dark:divide-[{ForegroundDark}75]"):
        if haslanguage(self.CodeBlockGuide, "Nim"):
          component LanguageChooser("Nim")
        if haslanguage(self.CodeBlockGuide, "Nim (SSR)"):
          component LanguageChooser("Nim (SSR)")
        if haslanguage(self.CodeBlockGuide, "Nim (SPA)"):
          component LanguageChooser("Nim (SPA)")
        if haslanguage(self.CodeBlockGuide, "Python"):
          component LanguageChooser("Python")
      for i in 0..<self.sources.len:
        nim:
          let source = self.sources.val[i]
        if currentLanguage == source.title:
          tCode(
            id = "{source.id}{self.uniqCompId}",
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
            tDiv(class = "flex bg-[#1a1b26] rounded-b-md"):
              tDiv(
                id = "{source.id}{self.uniqCompId}_play_button",
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
                    playButton = document.getElementById(fmt"{source.id}{self.uniqCompId}_play_button")
                    playResult = document.getElementById(fmt"{source.id}{self.uniqCompId}_play_result")
                    playStates: seq[tuple[text, html, lang: cstring, waitMs: int]] = source.playResult.states
                  var idx = 0

                  playButton.classList.add("hidden")
                  playResult.classList.remove("hidden")
                  playResult.innerHTML = ""
                
                  proc hiddenProc(text, html, lang: cstring, waitMs: int) =
                    if text.len == 0 and html.len == 0:
                      playButton.classList.remove("hidden")
                      playResult.classList.add("hidden")
                    elif html.len != 0:
                      playResult.innerHTML &= html
                    else:
                      playResult.innerHTML &= fmt"""<pre><code id="{self.uniqCompId}{lang}{idx}" language="{lang}" class="language-{lang}" style="padding-top: 0 !important; padding-bottom: 0 !important;">{text}</code></pre>"""
                      let id: cstring = fmt"{self.uniqCompId}{lang}{idx}"
                      inc idx
                      {.emit: """//js
                      let codeBlock = document.getElementById(`id`);
                      hljs.highlightElement(codeBlock);
                      """.}
                  
                  {.emit: """//js
                  const playStates = [...`playStates`];
                  let timeout = 0;

                  playStates.forEach(state => {
                    timeout += state.Field3;
                    setTimeout(
                      () => `hiddenProc`(state.Field0, state.Field1, state.Field2, state.Field3),
                      timeout
                    );
                    console.log(state.Field0, state.Field1, state.Field2, state.Field3);
                  });
                  """.}
              tDiv(id = "{source.id}{self.uniqCompId}_play_result", class = "w-full pb-4")
  
  @updated:
    for source in self.sources:
      highlight(self.CodeBlockGuide, source.id)
  
  [methods]:
    proc highlight(id: cstring) =
      let id: cstring = $id & self.uniqCompId
      {.emit: """//js
      let codeBlock = document.getElementById(`id`);
      if (codeBlock) {
        hljs.highlightElement(codeBlock);
      }
      """.}
    
    proc hasLanguage(lang: string): bool =
      for source in self.sources:
        if source.title == lang:
          return true
      false
