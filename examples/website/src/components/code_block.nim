import
  ../../../../src/happyx,
  regex


component CodeBlock:
  language: string = "nim"
  source: string = ""
  id: cstring = ""
  selections: seq[tuple[start: int, finish: int]] = @[]
  uniqueId: int = 1

  `template`:
    tPre(class = "relative"):
      if self.uniqueId == 1:
        tCode(id = "{self.id}", language = self.language, class = "rounded-md text-3xl lg:text-lg xl:text-base language-{self.language}"):
          {self.source}
      else:
        tCode(id = fmtnu"{self.id}", language = self.language, class = "rounded-md text-3xl lg:text-lg xl:text-base language-{self.language}"):
          {self.source}
      tDiv(class = "absolute right-4 top-4"):
        tSvg(
          viewBox = "0 0 24 24",
          class = "w-10 lg:w-6 h-10 lg:h-6 fill-white hover:fill-gray-200 active:fill-gray-400 transition-all cursor-pointer select-none"
        ):
          tPath("fill-rule"="evenodd", "clip-rule"="evenodd", d="M21 8C21 6.34315 19.6569 5 18 5H10C8.34315 5 7 6.34315 7 8V20C7 21.6569 8.34315 23 10 23H18C19.6569 23 21 21.6569 21 20V8ZM19 8C19 7.44772 18.5523 7 18 7H10C9.44772 7 9 7.44772 9 8V20C9 20.5523 9.44772 21 10 21H18C18.5523 21 19 20.5523 19 20V8Z")
          tPath(d="M6 3H16C16.5523 3 17 2.55228 17 2C17 1.44772 16.5523 1 16 1H6C4.34315 1 3 2.34315 3 4V18C3 18.5523 3.44772 19 4 19C4.55228 19 5 18.5523 5 18V4C5 3.44772 5.44772 3 6 3Z")
          @click:
            var data: cstring = self.source.val
            {.emit: "navigator.clipboard.writeText(`data`);".}

  @updated:
    self.highlight()
    echo "updated!"
  
  [methods]:
    proc highlight() =
      let id: cstring =
        if self.uniqueId == 1:
          $self.id & self.uniqCompId
        else:
          $self.id
      var innerHTML: cstring
      {.emit: """//js
      let codeBlock = document.getElementById(`id`);
      hljs.highlightElement(codeBlock);
      `innerHTML` = codeBlock.innerHTML;
      """.}
      var html = $innerHTML
      for selection in self.selections:
        var
          s = 0
          e = 0
          opened = 0
          idx = 0
          offset = 0
        for i in html:
          if idx == selection.start:
            s = offset
          if idx == selection.finish:
            e = offset
          if i == '<':
            inc opened
          elif i == '>':
            dec opened
          if opened == 0:
            inc idx
          inc offset
        html.insert("<span class='border-[1px] border-red-400 rounded-md'>", s)
        html.insert("</span>", e + 53)
      innerHTML = cstring html
      {.emit: """//js
      codeBlock.innerHTML = `innerHTML`;
      """.}
