import ../../src/happyx


component ComponentFor:
  counter: int

  `template`:
    tDiv:
      for i in 0..self.counter:
        tButton(class="rounded-full px-8 py-2 my-1 bg-neutral-300 hover:bg-neutral-400 transition-colors"):
          "{i}"
          nim:
            let iTmp = i
          @click:
            self.counter += 1
            echo iTmp
  
  @created:
    echo "created!"
  
  @updated:
    echo "updated!"
  
  @beforeUpdated:
    echo "before updated!"
  
  @pageHide:
    echo "page hide!"
  
  @pageShow:
    echo "page show!"
  
  @exited:
    echo "exited!"
