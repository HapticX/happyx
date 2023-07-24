import
  happyx,
  ../ui/colors


type Data = seq[tuple[name, url: string]]


component AboutSection:
  name: string
  data: Data

  `template`:
    tDiv(class = "flex flex-col gap-4"):
      tP(class = "font-semibold"):
        {self.name}
      tDiv(class = "flex flex-col gap-2"):
        for item in self.data:
          tA(href = item.url, class = "text-[{LinkForeground}] visited:text-[{LinkVisitedForeground}] hover:text-[{LinkActiveForeground}] translation-all"):
            {item.name}
