import
  ../src/happyx


var
  counter = remember 0
  isReadonly = remember true

appRoutes("app"):
  "/":
    tUl(class = "list-disc px-4"):
      for i in 0..counter:
        tLi:
          "{i}st elem 🍍"
    
    tButton(data-happyx-ok = "Hello from HappyX"):
      "click me"
      @click:
        counter += 1
        isReadonly.set(not isReadonly)
    
    tInput(readonly = counter.val mod 2 == 0)
    tInput(readonly = isReadonly)
