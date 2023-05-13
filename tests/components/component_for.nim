import ../../src/happyx


component ComponentFor:
  counter: int

  `template`:
    for i in 0..self.counter:
      tButton(class="rounded-full px-8 py-2 my-1 bg-neutral-300 hover:bg-neutral-400 transition-colors"):
        {i}
        @click:
          echo i
