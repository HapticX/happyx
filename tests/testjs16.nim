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

component withRepsSquared:
  n: int = 2
  `template`:
    withReps(2):
      slot


component A[T]:
  value: T
  html:
    tDiv:
      "value is {self.value}"
      when self.value is State[string]:
        tP:
          "Hello, value is string"
      tDiv:
        slot


component Some[T: int | float, A, B: string]:
  value: T
  x: A
  y: B
  `template`:
    tDiv:
      tP: "Some value is {self.value}"
      tP: "Some x,y is {self.x},{self.y}"


component B of A[int]:
  html:
    tDiv:
      "["
      super()
      "]"


# declare path params
pathParams:
  paramName int:  # assign param name
    optional  # param is optional
    mutable  # param is mutable variable
    default = 100  # default param value is 100


type counterObject* = ref object
  count*: int
  settings*: string

var counterObj1* = counterObject.new()
var counterObj2* = counterObject.new()
proc nextCounter*(c: counterObject): int =
  c.count += 1
  result = c.count

component withCounterObject:
  counter: counterObject = counterObj1
  count: int = nextCounter(counter)
  `template`:
    tDiv: "self count: {self.count}"
    tDiv: "count in template: {nextCounter(counterObj2)}"


appRoutes "app":
  "/":
    for i in 1..5:
      withCounterObject
    component withReps(5):
      withCounter()
      withRandom()
      "non-component rand {rand(99)}"
    component withRepsSquared(2):
      "non-component rand {rand(99)}"
  "/<paramName>":
    {paramName}
  "/compsT":
    tDiv:
      A[int](5)
      A[seq[int]](@[1, 2, 3, 4])
      A[string]("hello"):
        "im a slot"
      Some[int, string, string](5, "0", "1")
      B(5)
