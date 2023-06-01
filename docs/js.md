# Pure JS In Nim 👑

HappyX provides `buildJs` macro that provides PURE Js in Nim.

Here is example ✌
```nim
func myNimFunc(a: string) =
  echo a & " meow"

var myNimVar = "Hello!"

buildJs:
  # Translated into
  # let some = 0
  var some = 0

  # A lot of Nim code is available to convert to pure JavaScript
  block loop1:
    for i in 0..<3:
      block loop2:
        for j in 0..<3:
          if i == 1 && j == 1:
            continue loop1
          echo "i =", i, "j =", j
  
  type
    MyEnum = enum
      A, B, C
  
  var myEnum = MyEnum.A
  case myEnum:
  of A:
    ...
  else:  # if not all enum values in case than throws error
    ...
  
  class Rectangle:
    width*: float
    height*: float

    constructor(w, h):
      self.width = w
      self.height = h
    
    area():
      return self.width * self.height
  
  function myJsFunc(a, b, c):
    # work with a, b and c
    console.log(a)
    echo b, c
  
  myJsFunc(1, 2, 3)

  ~myNimVar = "Woof"
  echo ~myNimVar

  # You can use Nim code here:
  nim:
    myNimFunc(myNimVar)
```

---

This documentation was generated with [`HapDoc`](https://github.com/HapticX/hapdoc)
