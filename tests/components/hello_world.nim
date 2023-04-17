import
  ../../src/happyx,
  ./main


component HelloWorld:
  counter: int

  `template`:
    tDiv:
      {self.counter}
    tDiv:
      button:
        "Increase"
        @click:
          self.counter += 1
      button:
        "Go to /visit"
        @click:
          route("/visit")
  
  `script`:
    echo self.counter
    self.counter *= 2
  
  `style`:
    """
    button {
      border-radius: 5rem;
      padding: 0.4rem 1.5rem;
      border: 0;
      background: #dedede;
      color: #212121;
    }"""
