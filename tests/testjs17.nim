import
  ../src/happyx,
  std/macros


var someValue = remember 0

proc funcComp1(i: State[int], stmt: TagRef): TagRef =
  ## You can pass any amount of arguments.
  buildHtml:
    tDiv:
      "i is "
      {i}
      @click:
        i += 1
    stmt

proc funcComp2(i: State[int]): TagRef =
  buildHtml:
    tDiv:
      "second comp, so `i` is {i}"

proc funcComp3(): TagRef =
  buildHtml:
    tDiv:
      "third comp without arguments"


component NormalComp:
  i: State[int]
  html:
    tDiv:
      "And this is common component. i is {self.i}"


# dumpTree:
#   echo functionalComp is proc


appRoutes "app":
  "/":
    tDiv:
      "Here is functional components"
      funcComp1(someValue):
        "This is functional component slot"
      funcComp2(someValue)
      funcComp3()
      funcComp3
      NormalComp(someValue)
