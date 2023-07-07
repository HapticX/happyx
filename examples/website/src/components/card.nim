import
  happyx,
  ../ui/colors


component Card:
  pathToImg: string = ""

  `template`:
    tDiv(class = "flex flex-col justify-center items-center gap-4 select-none px-8 pt-2 pb-12 bg-[{Background}] bg-gradient-to-r dark:from-[{BackgroundDark}] dark:to-[{BackgroundSecondaryDark}] drop-shadow-2xl hover:scale-110 transition-all duration-300 rounded-md"):
      if self.pathToImg.len > 0:
        tImg(src = "{self.pathToImg}", class = "-mt-8 h-16 w-16 pointer-events-none")
      tDiv:
        slot