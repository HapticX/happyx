import ../../../../../src/happyx


component Message:
  text: cstring = ""
  fromId: int = 0

  `template`:
    tDiv(class = "flex flex-col"):
      {self.text}
      p(class = "self-end text-right text-sm"):
        "By User {self.fromId}"
  
  `script`:
    echo self.fromId
    echo self.text
