type
  PlayResult* = ref object
    states*: seq[tuple[text, html, lang: cstring, waitMs: int]]


proc newPlayResult*(states: seq[tuple[text, html, lang: cstring, waitMs: int]] = @[]): PlayResult =
  PlayResult(states: states)


let
  playHelloWorld* = newPlayResult(@[
    (cstring"$ curl -D- http://127.0.0.1:5000/", cstring"", cstring"shell", 250),
    (cstring"""
HTTP/1.1 200 OK
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
  playCreateSsrProject* = newPlayResult(@[
    (cstring"New HappyX project", cstring"", cstring"shell", 250),
    (cstring"Initializing project", cstring"", cstring"shell", 250),
    (cstring"""Templates in SSR was disabled. To enable add --template flag.""", cstring"", cstring"shell", 250),
    (cstring"Successfully created server project", cstring"", cstring"shell", 250),
    (cstring"", cstring"", cstring"", 10000)
  ])
  playCreateSsrProjectPython* = newPlayResult(@[
    (cstring"New HappyX project", cstring"", cstring"shell", 250),
    (cstring"Initializing project", cstring"", cstring"shell", 250),
    (cstring"""Templates in SSR was disabled. To enable add --template flag.""", cstring"", cstring"shell", 250),
    (cstring"""You choose Python programming language for this project.""", cstring"", cstring"shell", 250),
    (cstring"Successfully created server project", cstring"", cstring"shell", 250),
    (cstring"", cstring"", cstring"", 10000)
  ])
  playCreateSpaProject* = newPlayResult(@[
    (cstring"New HappyX project", cstring"", cstring"shell", 250),
    (cstring"Initializing project", cstring"", cstring"shell", 250),
    (cstring"""You choose tailwind css on project creation.
Read docs: https://tailwindcss.com/docs/""", cstring"", cstring"shell", 250),
    (cstring"Successfully created client project", cstring"", cstring"shell", 250),
    (cstring"", cstring"", cstring"", 10000)
  ])
