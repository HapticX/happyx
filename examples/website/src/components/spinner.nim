import
  ../../../../src/happyx,
  ../ui/colors


type SpinnerAction = proc(choosen: int): void

const DefaultSpinnerAction: SpinnerAction = proc(choosen: int) =
  discard


component Spinner:
  data: seq[string] = @[]
  action: SpinnerAction = DefaultSpinnerAction
  flat: bool = false
  lowercase: bool = true

  shown: bool = false

  `template`:
    tDiv(class = "flex flex-col"):
      tDiv(
        class =
          if self.lowercase:
            "flex flex-col justify-center items-center lowercase font-bold text-lg cursor-pointer select-none"
          else:
            "flex flex-col justify-center items-center font-bold text-lg cursor-pointer select-none"
      ):
        if self.flat:
          tDiv(class = "px-2 text-4xl lg:text-2xl xl:text-base md:px-4 xl:px-8 py-1 text-[{Foreground}] dark:text-[{ForegroundDark}] hover:opacity-80 active:opacity-60 transition-all duration-300"):
            slot
        else:
          tDiv(class = "px-2 text-4xl lg:text-2xl xl:text-base md:px-4 xl:px-8 py-1 text-[{Background}] dark:text-[{BackgroundDark}] rounded-md bg-[{Orange}] dark:bg-[{Yellow}] hover:opacity-90 active:opacity-75 transition-all duration-300"):
            slot
        @click:
          self.toggle()
      tDiv(class = "relative"):
        tDiv(id = "spinner_bg_{self.uniqCompId}", class = "absolute flex flex-col gap-2 py-2 gap-1 rounded-b-md bg-black/25 top-0 inset-x-0 pointer-events-none opacity-0 transition-all"):
          for i in 0..<self.data.len:
            tP(class = "flex justify-center items-center px-2 select-none cursor-pointer"):
              {self.data.val[i]}
              @click:
                if self.shown.isNil():
                  return
                self.toggle()
                self.action(i)
  
  [methods]:
    proc toggle() =
      enableRouting = false
      let spinnerBg = document.getElementById(fmt"spinner_bg_{self.uniqCompId}")
      if not self.shown.val:
        spinnerBg.classList.remove("opacity-0")
        spinnerBg.classList.add("opacity-100")
        spinnerBg.classList.remove("pointer-events-none")
        self.shown.set(true)
      else:
        spinnerBg.classList.remove("opacity-100")
        spinnerBg.classList.add("opacity-0")
        spinnerBg.classList.add("pointer-events-none")
        self.shown.set(false)
      enableRouting = true
