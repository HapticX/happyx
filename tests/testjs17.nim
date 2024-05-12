import
  ../src/happyx,
  std/macros


var someValue = remember 0
var test = remember ""

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
      "comp2, so `i` is {i}"

proc funcComp3(): TagRef =
  buildHtml:
    tDiv:
      "comp3 without arguments"

proc funcComp4(id = "", stmt: TagRef): TagRef =
  buildHtml:
    tDiv:
      "comp4 with body"
      tInput(id = id, value = test.val):
        @input:
          test.set($ev.target.value)
      stmt


proc Button(stmt: TagRef): TagRef =
  buildHtml:
    tDiv():
      stmt


component NormalComp:
  i: State[int]
  html:
    tDiv:
      "And this is common component. i is {self.i}"


appRoutes "app":
  "/":
    tDiv:
      "Here is functional components"
      funcComp1(someValue):
        "This is functional component slot"
      funcComp2(someValue)
      funcComp3()
      funcComp3
      funcComp4(id = "inp2"):
        "Hello"
        funcComp1(someValue):
          "This is functional component slot"
      funcComp4(id = "inp1"):
        "world"
      NormalComp(someValue)
      Button():
        "Click me"
      tButton():
        "Click me"
