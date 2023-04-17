import ../src/happyx
import macros


component HelloWorld:
  counter: int

  `template`:
    h1:
      "Hello, world!"
    button:
      "Increase"
      @button:
        inc self.counter
  
  `script`:
    echo "Hello, world!"
    echo self.counter
  
  `style`:
    """
    h1 {
      font-family: Monospace
    }
    """

var html = buildHtml:
  component HelloWorld
  component HelloWorld(counter = 100)

echo html
