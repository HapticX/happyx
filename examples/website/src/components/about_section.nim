import
  happyx,
  ../ui/colors


type Data = seq[tuple[name, url: string]]


component AboutSection:
  name: string
  data: Data

  `template`:
    tDiv(class = "flex flex-col gap-8 lg:gap-4"):
      tP(class = "font-semibold text-2xl lg:text-base"):
        # Section name
        {self.name}
      tDiv(class = "flex flex-col gap-4 lg:gap-2 text-xl lg:text-lg xl:text-base"):
        for item in self.data:
          # Section link
          tA(href = item.url, class = "text-[{LinkForeground}] visited:text-[{LinkVisitedForeground}] hover:text-[{LinkActiveForeground}] translation-all"):
            {item.name}
