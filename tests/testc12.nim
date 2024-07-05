import
  ../src/happyx,
  ../src/happyx/core/constants


var searchRemember = ""


component Button:
  html:
    tButton:
      "Click me to echo on server!"
      @click:
        echo "Hello, world"
        route(self, "/hello")
    tInput(placeholder = "input some ..."):
      @input(event):
        echo "value"
        js(self, fmt"""console.log({event["data"]});""")
    tDiv(class = "flex flex-col justify-center items-center gap-2"):
      tP(class = "text-2xl font-bold"):
        "Search anything"
      tInput(placeholder = "search", value = searchRemember):
        @input(event):
          # update current data
          echo event.target.value
          searchRemember = event.target.value.getStr
      tButton(class = "px-4 py-1 bg-sky-300 hover:bg-sky-400 active:bg-sky-500 duration-300 rounded-full"):
        "Search"
        @click:
          route(self, fmt"/search?q={searchRemember}")


liveview:
  "/":
    head:
      tTitle: "SSR Components are here!"
      tScript(src = "https://cdn.tailwindcss.com")
    component Button
    tScript: """
      function test() {
        console.log("called test() from server");
      }
    """
  "/hello":
    "Hello, world!"
    tButton:
      "Click me to go back"
      @click:
        route(hostname, "/")
  "/search":
    nim:
      let q = decodeUrl(query?q)
    tP: "You search: {q}"


serve("127.0.0.1", 5000):
  discard
