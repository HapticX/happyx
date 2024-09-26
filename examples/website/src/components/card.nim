import
  ../../../../src/happyx,
  ../ui/colors


proc Card*(pathToImg: string = "", alt: string = "", stmt: TagRef = nil): TagRef =
  buildHtml:
    tDiv(class = "flex flex-col hover:scale-110 duration-300 transition-all justify-center text-3xl lg:text-base items-center gap-4 select-none px-8 pt-2 pb-12 bg-[{Background}] dark:bg-[{BackgroundDark}] drop-shadow-xl rounded-md"):
      if pathToImg.len > 0:
        tImg(src = pathToImg, class = "-mt-8 h-16 w-16 pointer-events-none", alt = alt)
      tDiv:
        if not stmt.isNil:
          stmt
