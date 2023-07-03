import happyx


var html = buildHtml:
  tDiv:
    tInput(`type` = "password")
    tHr
    tScript: """
      var x = "Hello, world!";
    """
