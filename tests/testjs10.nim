import
  ../src/happyx


proc hello_world() =
  echo "Hello, world!"

# echo document.getElementById("app").id;
echo elem(app).id


var myComp =
  use:
    component Button:
      "This is button in component"


myComp.action.set(hello_world)


appRoutes("app"):
  "/":
    component Button(action=hello_world):
      "Click me!"
    component Button:
      "Click me!"
    
    component myComp
    
    tBr
    tBr

    component Input(placeholder = "Edit text ...", label = "Edit text ...")
