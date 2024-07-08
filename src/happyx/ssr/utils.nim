## # SSR Utils
## 
## provides some utils to working at server-side
## 
import
  std/json,
  std/httpcore,
  std/options,
  std/strtabs

when not defined(js):
  import std/terminal
  export terminal


type
  CustomHeaders* = StringTableRef


proc newCustomHeaders*: CustomHeaders =
  newStringTable().CustomHeaders


proc `[]=`*[T](self: CustomHeaders, key: string, value: T) =
  when not (T is string):
    self[key] = $value
  else:
    self[key] = value


proc toJsonNode*(headers: HttpHeaders | Option[HttpHeaders]): JsonNode =
  ## Converts [HttpHeaders](https://nim-lang.org/docs/httpcore.html#HttpHeaders)
  ## to [JsonNode](https://nim-lang.org/docs/json.html#JsonNode)
  result = newJObject()
  when headers is HttpHeaders:
    for k, v in headers.pairs():
      result[k] = newJString(v)
  else:
    for k, v in headers.get().pairs():
      result[k] = newJString(v)


proc toHttpHeaders*(json: JsonNode): HttpHeaders =
  ## Converts [JsonNode](https://nim-lang.org/docs/json.html#JsonNode)
  ## to [HttpHeaders](https://nim-lang.org/docs/httpcore.html#HttpHeaders)
  result = newHttpHeaders()
  for k, v in json.pairs():
    result[k] = v.getStr


when not defined(js):
  func fgColored*(text: string, clr: ForegroundColor): string {.inline.} =
    ## This function takes in a string of text and a ForegroundColor enum
    ## value and returns the same text with the specified color applied.
    ## 
    ## Arguments:
    ## - `text`: A string value representing the text to apply color to.
    ## - `clr`: A ForegroundColor enum value representing the color to apply to the text.
    ## 
    ## Return value:
    ## - The function returns a string value with the specified color applied to the input text.
    runnableExamples:
      echo fgColored("Hello, world!", fgRed)
    ansiForegroundColorCode(clr) & text & ansiResetCode
