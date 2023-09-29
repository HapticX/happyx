import happyx


component Task:
  isChecked: bool = false
  text: string = "Default text"

  `template`:
    class := (
      if self.isChecked:
        "flex gap-2 bg-green-400 rounded-xl px-4 py-2 w-full cursor-pointer select-none transition-all"
      else:
        "flex gap-2 bg-red-400 rounded-xl px-4 py-2 w-full cursor-pointer select-none transition-all"
    )
    tDiv(class="flex justify-center items-center w-6 h-6 rounded-md outline outline-1 outline-black"):
      if self.isChecked:
        "✔"
      else:
        "❌"
    tDiv(class="h-full"):
      {self.text}
    @click:
      self.isChecked = not self.isChecked
