import
  happyx,
  ../ui/colors


type ButtonAction = proc(): void

const DefaultButtonAction: ButtonAction = proc() =
  discard


component Button:
  flat: bool = false
  action: ButtonAction = DefaultButtonAction

  `template`:
    # Here you can use HTML DSL
    tDiv(class = "flex justify-center items-center lowercase font-bold text-lg cursor-pointer select-none"):
      if self.flat:
        tDiv(class = "px-8 py-1 text-[{Foreground}] hover:opacity-80 active:opacity-60 transition-all duration-300"):
          slot
      else:
        tDiv(class = "px-8 py-1 text-[{Background}] rounded-full bg-[{Foreground}] hover:opacity-90 active:opacity-75 transition-all duration-300"):
          slot
      @click:
        self.Button.action.val()()
