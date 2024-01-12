import
  ../../../../src/happyx,
  ../app_config,
  highlightjs


component CodeBlock:
  source: string
  lang: string

  html:
    tPre:
      tCode(language = "{self.lang}", class = "language-{self.lang} text-2xl lg:text-lg xl:text-base"):
        {self.source}

  @updated:
    hljs.highlightAll()
