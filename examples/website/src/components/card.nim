import
  happyx


component Card:
  id: cstring

  `template`:
    tDiv(id = "{self.id}", class = "flex will-change-transform justify-center items-center gap-12 w-fit drop-shadow-2xl rounded-md bg-white"):
      slot
