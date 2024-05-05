## # Queries ❔
## 
## Provides working with query params
import
  std/macros,
  std/strtabs,
  std/tables,
  std/strutils


proc parseQuery*(q: string): owned(StringTableRef) =
  ## Parses query and retrieves StringTableRef object
  runnableExamples:
    import strtabs
    let
      query = "a=1000&b=8000&password=mystrongpass"
      parsedQuery = parseQuery(query)
    assert parsedQuery["a"] == "1000"
  let query =
    if q.startsWith("?"):
      q[1..^1]
    else:
      q
  result = newStringTable()
  for i in query.split('&'):
    let splitted = i.split('=')
    if splitted.len >= 2 and not splitted[0].endsWith("[]"):
      result[splitted[0]] = splitted[1]


proc parseQueryArrays*(query: string): TableRef[string, seq[string]] =
  ## Parses query and retrieves TableRef[string, seq[string]] object
  runnableExamples:
    import tables
    let
      query = "a[]=10&a[]=100&a[]=foo&a[]=bar"
      parsedQuery = parseQueryArrays(query)
    assert parsedQuery["a"] == @["10", "100", "foo", "bar"]
  result = newTable[string, seq[string]]()
  let query =
    if query.startsWith("?"):
      query[1..^1]
    else:
      query
  for i in query.split('&'):
    let splitted = i.split('=')
    if splitted.len >= 2 and splitted[0].endsWith("[]"):
      let key = splitted[0][0..^3]
      if result.hasKey(key):
        result[key].add(splitted[1])
      else:
        result[key] = @[splitted[1]]


macro `?`*(strTable: StringTableRef | TableRef[string, seq[string]], key: untyped): untyped =
  ## Shortcut to get query param.
  ## 
  ## `High-level API`
  ## 
  ## ## Example
  ## 
  ## .. code-block::nim
  ##    get "/":
  ##      # exmple.com/?myParam=100
  ##      echo query?myParam
  ## 
  let
    keyStr = newLit($key)
  newCall("getOrDefault", strTable, keyStr)
