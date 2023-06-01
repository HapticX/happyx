import
  ../src/happyx


var nimVar = 100


buildJs:
  # Create class
  class Animal:
    say():
      discard
  class Cat extends Animal:
    say():
      echo "Meow"
  class Dog extends Animal:
    say():
      echo "Woof!"
  var dog = new Dog()
  var cat = new Cat()
  dog.say()
  cat.say()


proc myNimFunc(arg: string) =
  echo arg

buildJs:
  # using nim code inside buildJs
  nim:
    myNimFunc("Hello!")
    # and nested ...
    buildJs:
      echo "Hello from JS"
      nim:
        echo "Hello from Nim"
        buildJs:
          echo "Hello from nested nested Js"
          nim:
            echo "Hello from nested nested Nim"


buildJs:
  # translates into
  # let name = 123;
  var name = 123
  
  # translates into
  # const name1 = 123;
  # const name2 = 123;
  let name1 = 123
  const name2 = 123
  
  # translates into
  # let arr = [2, 4, 3, 2, 1]
  var arr = [2, 4, 3, 2, 1]
  echo arr
  
  # translates into
  # for (var i = 0; i < 10; ++i) { ... }
  for i in 0..10:
    echo i
  
  # translates into
  # for ((val, idx) in arr)
  for (val, idx) in arr:
    echo "val:", val, "and idx:", idx
  
  # translates into
  # function fun(a, b, c, d) { ... }
  function fun(a, b, c, d):
    # translates into
    # console.log(a, b, c, d)
    console.log(a, b, c, d)
    # translates into
    # console.log(a, b, c, d)
    echo a, b, c, d
  
  fun(5, 1, 2, 3)

  # translates into if-else statement
  if 5 === 2:
    ~nimVar = 2
  elif 5 === 4:
    ~nimVar = 4
  else:
    ~nimVar = 5
  
  var x = "hello"
  # translates into switch-case statement
  case x
  of 0:
    echo "x is 0"
  of 1, 2, 3, 4, 5:
    echo "0 <= x <= 5"
  of true:
    echo "x is true"
  else:
    echo "x is", x
  
  var a = 0
  while a < 10:
    ++a
    if a === 9:
      echo a * 1000
  
  discard
  discard console.log("Hello, world!")
  
  # translates into
  # class Rectangle extends Object { ... }
  class Rectangle extends Object:
    # translates into
    # #privateField
    privateField
    privateField1 = 100
    # translates into
    # publicField
    pub publicField
    pub publicField1 = 100
    
    # translates into
    # constructor(a)
    constructor(a):
      # translates into
      # this.publicField = a
      super()
      self.publicField = a
    
    # translates into
    # methodName()
    methodName():
      echo "Hello, world!"
    
      # Using nim variables:
      echo ~nimVar
  var rect = new Rectangle(100)
  echo rect.a

  type
    A = enum
      One, Two, Three,
      Four = 100
    B = object
      a: int
      b: string
      c*: seq[string]
  
  var enumA = A.One

  eval("console.log('Hello, world!')")

  case enumA:
  of A.One:
    echo "Hi!"
  else:
    echo "Bye!"
  
  block loop1:
    for i in 0..<3:
      block loop2:
        for j in 0..<3:
          if i == 1 && j == 1:
            continue loop1
          echo "i =", i, "j =", j

echo nimVar
