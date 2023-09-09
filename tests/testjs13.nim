import ../src/happyx
import random


component Num:
  n: int
  `template`:
    tSpan(style="margin-left:1em;"): {self.n}

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
