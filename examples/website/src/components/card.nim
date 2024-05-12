import
  ../../../../src/happyx,
  ../ui/colors


proc Card*(pathToImg: string = "", stmt: TagRef = nil): TagRef =
  buildHtml:
    tDiv(class = "flex flex-col justify-center text-3xl lg:text-base items-center gap-4 select-none px-8 pt-2 pb-12 bg-[{Background}] bg-gradient-to-r dark:from-[{BackgroundTerniaryDark}] dark:to-[{BackgroundSecondaryDark}] drop-shadow-xl hover:scale-110 transition-all duration-300 rounded-md"):
      if pathToImg.len > 0:
        tImg(src = pathToImg, class = "-mt-8 h-16 w-16 pointer-events-none")
      tDiv:
        if not stmt.isNil:
          stmt
