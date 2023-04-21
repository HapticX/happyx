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
    """
    button {
      border-radius: 5rem;
      padding: 0.4rem {self.counter * 0.2}rem;
      border: 0;
      background: #dedede;
      color: #212121;
    }"""
