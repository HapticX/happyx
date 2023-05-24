import
  ../src/happyx


var
  test = "#cdedad"

var s = buildStyle:
  import url("asdasdasdasd")
  # equivalent .className
  class className:
    color: {{test}}
    padding: 2.rem
    margin: 0 10.px 20.rem 0.rem
    background-color: rgba(255, 255, 255, 0.1)
    long-long-long-prop-key: rgba(255, 255, 255, 0.1)
  class li.spacious:
    color: red
  # equivalent #myElem
  id myElem:
    color: green
  # equivalent @keyframes anim
  @keyframes anim:
    # equivalent 0%
    0:
      transform: translateX(-150.px)
      opacity: 0
    # equivalent 100%
    100:
      transform: translateX(0.px)
      opacity: 1
  # equivalent @media not (screen and color), print and color
  @media not (screen and color), print and color:
    color: 0xFF5511
  tag body:
    background: gray
  # equivalent button:hover
  button@hover:
    color: red
  @charset "UTF-8"
  @supports (display: flex):
    @media screen and (min-width: 900.px):
      tag article:
        display: flex


echo s
