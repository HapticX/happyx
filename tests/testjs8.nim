import
  ../src/happyx


var
  counter = remember 0

appRoutes("app"):
  "/":
    tUl(class = "list-disc px-4"):
      for i in 0..counter:
        tLi:
          "{i}st elem 🍍"
    
    tButton:
      "click me"
      @click:
        counter += 1
