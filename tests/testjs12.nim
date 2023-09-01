# issue 122
import ../src/happyx

component CTestChild:
  id: int
  color: cstring
  `template`:
    tDiv(style = fmt"color:{self.color}"):
      "subcomponent ID: {self.id} {self.uniqCompId}"

var ctest1 = use component CTestChild(id = 1, color = "green")

component CTest:
  id: int
  # newId: int = id + 1
  # testChild: CTestCHild = CTestChild(id = 44, color = "purple")
  ### won't compile
  newId: cstring = fmt"newId: {self.id}"
  message: cstring = ""
  `template`:
    tButton:
      "get Id"
      @click:
        # ### self is CTest ### #
        # self.message = fmt"{self.getId()}"
        echo fmt"{self.getId()}"
        echo fmt"{self.id}"
        self.message = fmt"{self.id}"
    component CTestChild(id = 5, color = "gray")
    component CTestChild(id = 6, color = "gray")
    component CTestChild(id = 7, color = "gray")
  [methods]:
    proc getId(): int = self.id

var test1 = use component CTest(id = 1)

appRoutes("app"):
  "/":
    tDiv: component test1
    tDiv: component CTest(id = 7)