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
  n: int = 5
  `template`:
    for i in 1..self.n.val:
      tDiv(style="border: 0.2em dotted gray;"):
        slot


appRoutes "app":
  "/":
    component withReps():
      withCounter()
      withRandom()
      "non-component rand {rand(99)}"
