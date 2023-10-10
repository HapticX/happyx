import ../src/happyx


component CTestChild:
  id: int
  color: cstring
  `template`:
    tDiv(style=fmt"color:{self.color};"):
      "subcomponent ID: {self.id}"

var ctest1 = use component CTestChild(id=1, color = "green")

component CTest:
  id: int
  newId: cstring = "newId: " & $id
  message: cstring = ""
  child: CTestChild = use component CTestChild(id = self.id.val, color ="red")
  `template`:
    self.child.val
    script: """
    var x = 0
    """
   #component self.child
    tDiv: "template: {self.id} {self.newId}"

var test1 = use component CTest(id = 1)


var catStatus: string
var catLife: bool = false

if catLife:
  catStatus = "alive"
else:
  catStatus = "dead"


appRoutes("app"):
  "/":
    tDiv: test1
    tDiv: CTest(id = 7)
    tDiv: CTest(9)
    tDiv:
      CTest(id = 0):
        "hello"
  
  "/issue154":
    tDiv: {catStatus}
    var
      dogStatus = "superposition"
      dogLife: bool = false
    if dogLife:
      dogStatus = "alive"
    else:
      dogStatus = "dead"
    tDiv(style="color:red;"):  # <- for this
      {dogStatus}
      # Attrs declaration for tDiv with `style`
      myAttr := "asd"
      myAttr1 := 1123
