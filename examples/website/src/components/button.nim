import
  ../../../../src/happyx,
  ../ui/colors


type ButtonAction = proc(): void

const
  DefaultButtonAction: ButtonAction = proc() = discard


proc Button*(flat: bool = false, action: ButtonAction = DefaultButtonAction, lowerCase: bool = true,
             stmt: TagRef = nil): TagRef =
  buildHtml:
    # Here you can use HTML DSL
    tDiv(
      class =
        if lowerCase:
          "flex justify-center items-center lowercase font-bold text-lg cursor-pointer select-none"
        else:
          "flex justify-center items-center font-bold text-lg cursor-pointer select-none"
    ):
      if flat:
        tDiv(class = "px-2 text-4xl lg:text-2xl xl:text-base md:px-4 xl:px-6 py-1 text-[{Foreground}] dark:text-[{ForegroundDark}] hover:opacity-80 active:opacity-60 duration-300"):
          if not stmt.isNil:
            stmt
      else:
        tDiv(class = "px-2 text-4xl lg:text-2xl xl:text-base md:px-4 xl:px-6 py-1 text-[{Background}] dark:text-[{BackgroundDark}] rounded-md bg-[{Orange}] dark:bg-[{Yellow}] hover:opacity-90 active:opacity-75 duration-300"):
          if not stmt.isNil:
            stmt
      @click:
        action()
