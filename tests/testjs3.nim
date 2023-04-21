import ../src/happyx
import components/[nested_component]


component HelloWorld:
  counter: int

  `template`:
    h1:
      "Hello, world!"
    button:
      "Increase"
      @button:
        self.counter += 1
  
  `script`:
    echo "Hello, world!"
    echo self.counter
  
  `style`:
    """
    h1 {
      font-family: Monospace
    }
    """

var nested = buildHtml:
  component NestedComponent2(counter = 100)

echo nested
