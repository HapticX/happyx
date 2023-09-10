import ../src/happyx
import random


component Num:
  n: int
  `template`:
    tSpan(style="margin-left:1em;"): {self.n}

component NumSq:
  m: int
  `template`:
    tDiv: "{self.m} squared is: "
    component Num(self.m.val * self.m.val)

randomize()

appRoutes("app"):
  "/":
    for i in 1..3: tDiv:
      for j in 1..3:
        for k in 1..3:
          #component Num(i+j+k)
          # {i+j+k}
          # tSpan(style="margin-left: 1em"):  {rand(99)}
          component Num(rand(99))
    tDiv:
      component NumSq(5)
      component NumSq(3)
