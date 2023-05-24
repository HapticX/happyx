import ../../src/happyx


component HelloWorld:
  counter: float

  `template`:
    tDiv:
      {self.counter}
    tDiv:
      button:
        "Increase"
        @click:
          echo self.counter
          self.counter += 1.0
      button:
        "Go to /visit"
        @click:
          route("/visit")
  
  `script`:
    echo self.counter
  
  `style`:
    buildStyle:
      tag button:
        border-radius: 5.rem
        padding: 0.4.rem {{self.counter * 0.2}}.rem
        border: 0
        background: rgb(200, 200, 200)
        color: rgb(33, 33, 33)
