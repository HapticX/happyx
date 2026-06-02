## Regression for https://github.com/HapticX/happyx/issues/404
import
  std/strutils,
  std/unittest,
  ../src/happyx


component Payload:
  i: int
  j: int
  html:
    tDiv: "delivered i={self.i.val},j={self.j.val}"


proc order(i, j: int): TagRef =
  buildHtml:
    tDiv: "ordering i={i},j={j}"
    Payload(i, j)


when enableDefaultComponents:
  component Order:
    i: int
    j: int
    html:
      tDiv: "ordering i={self.i.val},j={self.j.val}"
      Payload(self.i.val, self.j.val)


proc collectDelivered(root: TagRef): seq[string] =
  var acc: seq[string] = @[]
  proc walk(t: TagRef) =
    if t.isText:
      let s = $t.name
      if s.startsWith("delivered"):
        acc.add(s)
    for c in t.children:
      walk(c)
  walk(root)
  acc


suite "functional components in nested for (#404)":
  test "order(i,j) passes loop values into child component":
    var got: seq[string] = @[]
    let page = buildHtml:
      tDiv:
        for i in 1..2:
          for j in 1..2:
            order(i, j)
    got = collectDelivered(page)
    check got.len == 4
    check "delivered i=1,j=1" in got
    check "delivered i=1,j=2" in got
    check "delivered i=2,j=1" in got
    check "delivered i=2,j=2" in got

  when enableDefaultComponents:
    test "standard component Order matches functional order":
      var funcOut, compOut: seq[string] = @[]
      let funcPage = buildHtml:
        tDiv:
          for i in 1..2:
            for j in 1..2:
              order(i, j)
      let compPage = buildHtml:
        tDiv:
          for i in 1..2:
            for j in 1..2:
              Order(i, j)
      funcOut = collectDelivered(funcPage)
      compOut = collectDelivered(compPage)
      check funcOut == compOut
