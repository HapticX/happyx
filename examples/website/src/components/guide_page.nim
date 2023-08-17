# Import HappyX
import
  ../../../../src/happyx,
  ../ui/colors,
  ./[button, drawer, sidebar],
  unicode


var
  currentData* = remember getFileText("0_user_guide", "0_general", "0_introduction.md")
  nextFile* = remember getNextFile("0_user_guide", "0_general", "0_introduction.md")
  prevFile* = remember getPrevFile("0_user_guide", "0_general", "0_introduction.md")

proc callback*(a, b, c: string) =
  currentData.set(getFileText(a, b, c))
  nextFile.set(getNextFile(a, b, c))
  prevFile.set(getPrevFile(a, b, c))
  currentGuidePage.set((a, b, c))
  buildJs:
    hljs.highlightAll()


proc nextFileText*(): string =
  getFileText(nextFile.val[0], nextFile.val[1], nextFile.val[2])

proc prevFileText*(): string =
  getFileText(prevFile.val[0], prevFile.val[1], prevFile.val[2])


# Declare component
component GuidePage:

  # Declare HTML template
  `template`:
    tDiv(
      class = "flex flex-col text-xl lg:text-lg xl:text-base w-full h-full px-4 lg:px-12 xl:px-24 py-2 bg-[{BackgroundSecondary}] dark:bg-[{BackgroundSecondaryDark}] gap-8"
    ):
      tDiv(id = "guidePage", class = "flex flex-col gap-4"):
        {currentData}
      tDiv(class = "flex justify-between items-center w-full pb-8"):
        if nextFileText() != "NOTFOUND":
          component Button(
              action = proc() =
                callback(nextFile.val[0], nextFile.val[1], nextFile.val[2])
          ):
            nim:
              let nextTitle = nextFile.val[2].replace(re"\d+_", "").replace("_", " ").replace(".md", "").capitalize()
            "🠐 {nextTitle}"
        if prevFileText() != "NOTFOUND":
          component Button(
              action = proc() =
                callback(prevFile.val[0], prevFile.val[1], prevFile.val[2])
          ):
            nim:
              let prevTitle = prevFile.val[2].replace(re"\d+_", "").replace("_", " ").replace(".md", "").capitalize()
            "{prevTitle} 🠒"
  
  @updated:
    buildJs:
      var elem = document.getElementById("guidePage")
      elem.innerHTML = mdConv.makeHtml(elem.innerHTML)
