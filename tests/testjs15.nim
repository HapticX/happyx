import ../src/happyx


component withPresets:
  n: int = 5
  s: string = $n
  `template`:
   {self.s}


component withSlot:
  s: string = $1
  `template`:
   "The number is {self.s}, and the slot is "
   slot


appRoutes("app"):
  "/issue183":
    tDiv: component withPresets
    tDiv: component withPresets(s= "I better not be 5")
  
  "/issue184":
    var x = buildHtml(tDiv):
      "Hello?"
    buildHtml:
      x
      x
      x:
        "world!"
  
  "/issue185":
    tDiv:
      component withSlot(): "one"
    tDiv:
      component withSlot($7): "seven"
    tDiv:
      withSlot(): "one"
    #tDiv:
      #withSlot($7): "seven"
