import ../../src/happyx


component NestedComponent1:
  counter: int = 0

  `template`:
    tDiv:
      class = "p-28 bg-red-200"
      {self.counter}
      @click:
        echo self.counter
        self.counter += 1


component NestedComponent2:
  counter: int = 0

  `template`:
    tDiv:
      class = "p-28 bg-blue-200"
      {self.counter}
      component NestedComponent1
      tButton:
        "Click!"
        @click:
          echo self.counter
          self.counter += 1
