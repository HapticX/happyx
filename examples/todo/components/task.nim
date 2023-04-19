import happyx


component Task:
  isChecked: bool = false
  text: string = "Default text"

  `template`:
    class = "flex gap-2 bg-gray-800 rounded-xl px-4 py-2 text-white w-fit cursor-pointer select-none"
    tDiv(class="flex justify-center items-center w-6 h-6 rounded-md border-[1px] border-white"):
      if self.isChecked:
        "X"
    tDiv(class="w-fit"):
      {self.text}
    @click:
      self.isChecked = not self.isChecked
