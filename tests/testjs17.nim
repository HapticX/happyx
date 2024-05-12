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

# proc funcComp2(i: State[int]): TagRef =
#   buildHtml:
#     tDiv:
#       "comp2, so `i` is {i}"

# proc funcComp3(): TagRef =
#   buildHtml:
#     tDiv:
#       "comp3 without arguments"

proc funcComp4(stmt: TagRef): TagRef =
  static:
    echo declared(stmt) and stmt is TagRef
  buildHtml:
    tDiv:
      "comp4 with body"
      stmt


# component NormalComp:
#   i: State[int]
#   html:
#     tDiv:
#       "And this is common component. i is {self.i}"


appRoutes "app":
  "/":
    tDiv:
      # "Here is functional components"
      # funcComp1(someValue):
      #   "This is functional component slot"
      # funcComp2(someValue)
      # funcComp3()
      # funcComp3
      funcComp4():
        "Hello"
        funcComp1(someValue):
          "This is functional component slot"
      !debugCurrent
      # funcComp4:
      #   "world"
      # NormalComp(someValue)
