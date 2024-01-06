import
  ../src/happyx,
  random


randomize()

component withRandom:
  n: int = rand(99)
  `template`:
    tDiv: "self random: {self.n.val}"
    tDiv: "random in template: {rand(99)}"

var counter: int = 0
var counter2: int = 0
proc nextCounter(c: var int = counter): int =
  c += 1
  result = c

component withCounter:
  count: int = nextCounter()
  `template`:
    tDiv: "self count: {self.count}"
    tDiv: "count in template: {nextCounter(counter2)}"

component withReps:
  n: int
  `template`:
    for i in 1..self.n:
      tDiv(style="border: 0.2em dotted gray;"):
        slot

# declare path params
pathParams:
  paramName int:  # assign param name
    optional  # param is optional
    mutable  # param is mutable variable
    default = 100  # default param value is 100
  arg13 int:
    optional
    mutable
    default = 100

appRoutes "app":
  "/":
    component withReps(5):
      withCounter()
      withRandom()
      "non-component rand {rand(99)}"
  "/<paramName>":
    {paramName}
