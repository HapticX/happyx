# CSS In Nim 👑

You can write CSS in Pure Nim with `buildStyle` macro ✌.

```nim
buildStyle:
  tag tDiv:
    # div
    background-color: rgb(100, 200, 255)
    padding: 0 1.px 2.rem 3.em
  class myClass:
    # .myClass
    color: red
  tDiv@hover:
    # div:hover
    color: blue
  
  @supports (display: flex):
    @media screen and (min-width: 900.px):
      tag article:
        display: flex
```

---

This documentation was generated with [`HapDoc`](https://github.com/HapticX/hapdoc)
