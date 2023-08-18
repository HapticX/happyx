type
  PlayResult* = ref object
    states*: seq[tuple[text, html, lang: cstring, waitMs: int]]


proc newPlayResult*(states: seq[tuple[text, html, lang: cstring, waitMs: int]] = @[]): PlayResult =
  PlayResult(states: states)


let
  playHelloWorld* = newPlayResult(@[
    (cstring"$ curl -D- http://127.0.0.1:5000/", cstring"", cstring"shell", 250),
    (cstring"""HTTP/1.1 200 OK
Content-Type: text/plaintext

Hello, world!
""", cstring"", cstring"http", 500),
    (cstring"", cstring"", cstring"", 10000)
  ])
  playHelloWorldSPA* = newPlayResult(@[
    (cstring"", cstring"""
<div class="w-full h-48 bg-white text-black", style="font-family: serif; font-size: 100%;">
  Hello, world!
</div>
""", cstring"", 100),
    (cstring"", cstring"", cstring"", 10000)
  ])
