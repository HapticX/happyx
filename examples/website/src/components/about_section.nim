import
  ../../../../src/happyx,
  ../ui/colors


proc AboutSection*(name: string, data: seq[tuple[name, url: string]]): TagRef =
  buildHtml:
    tDiv(class = "flex flex-col gap-8 lg:gap-4"):
      tP(class = "font-semibold text-2xl lg:text-base"):
        # Section name
        {name}
      tDiv(class = "flex flex-col gap-4 lg:gap-2 text-xl lg:text-lg xl:text-base"):
        for item in data:
          # Section link
          tA(href = item.url, class = "text-[{LinkForeground}] visited:text-[{LinkVisitedForeground}] hover:text-[{LinkActiveForeground}] translation-all"):
            {item.name}
