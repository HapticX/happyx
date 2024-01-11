import
  ../../../../src/happyx,
  ./[code_block, button],
  ../ui/[steps, translations, colors, monaco]


component GuideInteractive:
  *steps: seq[Step]
  language: string
  source: string
  id: cstring
  *current_step: int = 0

  `template`:
    tDiv(class = "flex w-full bg-[{Background}] dark:bg-[{BackgroundDark}] overflow-hidden rounded-md"):
      tDiv(class = "w-1/2"):
        for i in 0..<self.steps.len:
          if self.current_step == i:
            CodeBlock(self.language, self.source, self.id, self.steps.val[i].selections, -1)
      tDiv(class = "flex flex-col py-4 px-2 w-1/2 gap-4"):
        slot
        tDiv(class = "flex flex-col items-center"):
          tP(class = "text-center font-bold"):
            {self.steps.val[self.current_step.val].title}
          tP(class = "text-center"):
            {self.steps.val[self.current_step.val].text}
          tDiv(class = "flex w-full justify-between pt-6"):
            if self.steps.val[self.current_step.val].prev >= 0:
              tButton(class = "opacity-[.8] hover:opacity-[.9] active:opacity-[1] duration-150"):
                {translate"👈 previous step"}
                @click:
                  self.current_step.set(self.steps.val[self.current_step.val].prev)
                  route(currentRoute)
                  application.router()
            else:
              tP
            if self.steps.val[self.current_step.val].next >= 0:
              tButton(class = "opacity-[.8] hover:opacity-[.9] active:opacity-[1] duration-150"):
                {translate"next step 👉"}
                @click:
                  self.current_step.set(self.steps.val[self.current_step.val].next)
                  route(currentRoute)
                  application.router()
