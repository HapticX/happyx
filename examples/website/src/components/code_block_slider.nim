import
  ../../../../src/happyx,
  ../ui/[colors, code, translations],
  ./[code_block]


type Code* = object
  text*: string
  language*: string
  name*: string
  description*: string


component CodeBlockSlider:
  data: seq[Code] = @[]

  index: int = 0

  `template`:
    tDiv(class = "flex flex-col w-full lg:w-3/4 xl:w-1/2 gap-6 rounded-md px-8 py-4"):
      tDiv(class = "relative"):
        for idx, val in (self.data).pairs:
          if idx == 0:
            tDiv(
              id = fmt"sliderContainer-{self.uniqCompId}_{idx}",
              class = "w-full flex flex-col lg:flex-row gap-4 lg:gap-2 justify-between transition-all duration-300 opacity-1"
            ):
              tDiv(class = "flex flex-col gap-2 lg:gap-0"):
                tP(class = "break-keep whitespace-pre text-5xl lg:text-xl xl:text-3xl font-bold pointer-events-none"):
                  {translate(val.name)}
                tP(class = "flex h-full justify-center items-center text-3xl lg:text-base pointer-events-none"):
                  {translate(val.description)}
              tDiv(class = "w-full"):
                component CodeBlock(source = val.text, language = val.language, id = fmt"slider-{self.uniqCompId}_{idx}")
          else:
            tDiv(
              id = fmt"sliderContainer-{self.uniqCompId}_{idx}",
              class = "w-full flex flex-col lg:flex-row gap-4 lg:gap-2 justify-between transition-all duration-300 absolute top-0 left-0 opacity-0"
            ):
              tDiv(class = "flex flex-col gap-2 lg:gap-0"):
                tP(class = "break-keep whitespace-pre text-5xl lg:text-xl xl:text-3xl font-bold pointer-events-none"):
                  {translate(val.name)}
                tP(class = "flex h-full justify-center items-center text-3xl lg:text-base pointer-events-none"):
                  {translate(val.description)}
              tDiv(class = "w-full"):
                component CodeBlock(source = val.text, language = val.language, id = fmt"slider-{self.uniqCompId}_{idx}")
      tDiv(class = "flex w-full justify-center items-center p-2 gap-2"):
        for idx in 0..<(self.data).len:
          if self.index == idx:
            tDiv(
              id = fmt"circle-{self.uniqCompId}_{idx}",
              class = "transition-all duration-300 overflow-hidden w-24 h-8 lg:w-18 lg:h-6 xl:w-12 xl:h-4 bg-[{Foreground}] dark:bg-[{ForegroundDark}] rounded-full cursor-pointer"
            ):
              @click:
                enableRouting = false
                updateIndex(self.CodeBlockSlider, idx)
                enableRouting = true
              tDiv(
                id = fmt"circle-{self.uniqCompId}_{idx}-fill",
                class = "w-0 h-full bg-[{Yellow}] dark:bg-[{Orange}] transition-all duration-[5000ms] rounded-full ease-linear z-40"
              ):""
          else:
            tDiv(
              id = fmt"circle-{self.uniqCompId}_{idx}",
              class = "transition-all duration-300 overflow-hidden w-8 h-8 lg:w-6 lg:h-6 xl:w-4 xl:h-4 bg-[{Foreground}] dark:bg-[{ForegroundDark}] rounded-full cursor-pointer"
            ):
              @click:
                enableRouting = false
                updateIndex(self, idx)
                enableRouting = true
              tDiv(
                id = fmt"circle-{self.uniqCompId}_{idx}-fill",
                class = "w-0 h-full bg-[{Yellow}] dark:bg-[{Orange}] transition-all duration-[5000ms] rounded-full ease-linear z-40"
              ):""
  
  @created:
    self.nextIndex()
  
  [methods]:
    proc nextIndex() =
      proc upd() =
        enableRouting = false
        self.updateIndex(
          if self.index < self.data.len - 1:
            self.index + 1
          else:
            0
        )
        {.emit: """//js
        setTimeout(() => { `upd`() }, 5000);
        """.}
        enableRouting = true
      {.emit: """//js
      setTimeout(() => { `upd`() }, 5000);
      """.}

    proc updateIndex(idx: int) =
      if self.index == idx:
        return
      self.index.set(idx)
      let index: int = self.index
      for idx, val in (self.data)->pairs:
        let id: cstring = fmt"slider-{self.uniqCompId}_{idx}"
        {.emit: """//js
        let codeBlock = document.getElementById(`id`);
        if (codeBlock) {
          hljs.highlightElement(codeBlock);
        }
        """.}

        let
          container = document.getElementById(fmt"sliderContainer-{self.uniqCompId}_{idx}")
          circle = document.getElementById(fmt"circle-{self.uniqCompId}_{idx}")
          fill = document.getElementById(fmt"circle-{self.uniqCompId}_{idx}-fill")
        if container.isNil():
          return
        if index == idx:
          container.classList.remove("absolute")
          container.classList.remove("top-0")
          container.classList.remove("left-0")
          container.classList.remove("opacity-0")
          container.classList.add("opacity-1")
          circle.classList.remove("xl:w-4")
          circle.classList.remove("lg:w-6")
          circle.classList.remove("w-8")
          circle.classList.add("xl:w-12")
          circle.classList.add("lg:w-18")
          circle.classList.add("w-24")
          fill.classList.remove("w-0")
          fill.classList.add("w-full")       
          fill.classList.add("transition-all")   
          fill.classList.add("ease-linear")     
          fill.classList.add("duration-[5000ms]")
        else:
          container.classList.remove("opacity-1")
          container.classList.add("absolute")
          container.classList.add("top-0")
          container.classList.add("left-0")
          container.classList.add("opacity-0")
          circle.classList.remove("xl:w-12")
          circle.classList.remove("lg:w-18")
          circle.classList.remove("w-24")
          circle.classList.add("xl:w-4")
          circle.classList.add("lg:w-6")
          circle.classList.add("w-8")
          fill.classList.remove("transition-all")     
          fill.classList.remove("ease-linear")
          fill.classList.remove("duration-[5000ms]")
          fill.classList.remove("w-full")
          fill.classList.add("w-0")
