import
  ../src/happyx


component Constructor:
  privateField: int = 0

  issue99: seq[string]

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
  `script`:
    echo fmt"Hello from Constructor {self.uniqCompId} ({self.privateField})"
  
  `style`: """
    div {
      background: #ffeced
    }
  """


component ConstructorChild of Constructor:
  constructor():
    self.privateField = remember 100_000
  
  `template`:
    tDiv:
      "ConstructorChild"
      tDiv(style = "padding-left: .5rem"):
        super()
  
  `script`:
    super()
    echo "Hi from child"
  
  `style`: """
    div {
      color: green;
    }
  """

importComponent "example.hpx" as Example
importComponent "button.hpx" as Button

var constructor = use:
  component Constructor->construct()

var compWithoutArgs = use:
  component Constructor(issue99 = @[])


appRoutes "app":
  "/":
    component compWithoutArgs
    component Constructor(privateField = 100, @[])
    component constructor
    component Constructor->construct()
    component Constructor->construct(val = 100):
      "Hello, world!"
    component ConstructorChild->construct()
    component Button:
      "Hello, world!"
  
  "/cookiesTest":
    tDiv:
      "Hello, world!"
      {cookies}