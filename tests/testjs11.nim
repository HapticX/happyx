import
  ../src/happyx


component Constructor:
  privateField: int = 0

  constructor(val: int):
    ## Some information about this constructor
    echo 1
    self.privateField = remember val * 2

  constructor():
    ## Some information about this constructor
    echo 2
    self.privateField = remember 10

  `template`:
    tDiv:
      {self.privateField}


var constructor = use:
  component Constructor->construct()

var compWithoutArgs = use:
  component Constructor


appRoutes "app":
  "/":
    component compWithoutArgs
    component Constructor(privateField = 100)
    component constructor
    component Constructor->construct()
    component Constructor->construct(val = 100):
      "Hello, world!"
