# issue 122
import ../src/happyx

component CTestChild:
  id: int
  color: cstring
  `template`:
    tDiv(style=fmt"color:{self.color}"):
      "subcomponent ID: {self.id}"

var ctest1 = use component CTestChild(id=1, color = "green")

component CTest:
  id: int
  # newId: int = id + 1
  # testChild: CTestCHild = CTestChild(id = 44, color = "purple")
  ### won't compile
  newId: cstring = "newId: " & $id
  message: cstring = ""
  `template`:
    tDiv: "template: {self.id} {self.newId}"
    tDiv: "message: {self.message}"
    tButton:
      "log id"
      @click:
        console.log(self.id)
    tButton:
      "get Id"
      @click:
        # ### self is CTest ### #
        # self.message = fmt"{self.getId()}"
        echo fmt"{self.getId()}"
        echo fmt"{self.id}"
        self.message = fmt"{self.id}"
    component CTestChild(id = 3, color = "red")
    component CTestChild(id = self.id, color = "blue") # undefined
    #component CTestChild(id = self.id, color = "blue") # same as above
    component ctest1
  [methods]:
    proc getId(): int = self.id

var test1 = use component CTest(id= 1)

appRoutes("app"):
  "/":
    tDiv: component test1
    tDiv: component CTest(id = 7)