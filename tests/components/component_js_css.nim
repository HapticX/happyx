## This component is fully support HTML, CSS and JS but in PURE Nim
## 
import ../../src/happyx


component Pure:
  `template`:
    # HTML here
    "Hi, HTML is here ✨"
    tDiv(class = "myClass"):
      "Yeap"
  
  `script` as js:
    echo "Hello, JS!"

    function myFunc(a):
      echo a
    
    myFunc(100)
  
  `style` as css:
    tag tDiv:
      color: rgb(200, 100, 200)
      background: rgb(21, 21, 21)
