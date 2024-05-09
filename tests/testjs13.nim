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

component Test: 
  someValue : string = "test"
  `template`:
    tDiv:
      tInput(id = "test", type = "text", value=self.someValue):
        @keyup:
          echo 123
          echo $ev.target.value
          self.someValue = $ev.target.value
        @input:
          echo $ev.target.value
        @click:
          echo "input focused"
      tButton():
        "Click me"
        @click:
          echo 1
      tDiv():
        {self.someValue}


# Declare component
component HelloWorld:
  `template`:
    component Test()


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
  "/issue146":
    component HelloWorld
