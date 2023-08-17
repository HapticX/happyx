# Import HappyX
import
  ../../../../src/happyx,
  ../ui/colors,
  ./[button, drawer],
  regex,
  unicode,
  macros,
  json,
  os


macro docs*(): untyped =
  result = newCall("%*")
  var
    documentationData = newJObject()
    obj = newNimNode(nnkTableConstr)

  for file in os.walkDirRec("./docs"):
    let splitted = file.split({DirSep, AltSep})
    var
      current = documentationData
      currentNode = obj
    for i in 1..<splitted.len-1:
      if not current.hasKey(splitted[i]):
        current[splitted[i]] = newJObject()
        currentNode.add(newNimNode(nnkExprColonExpr).add(newLit(splitted[i]), newNimNode(nnkTableConstr)))
      current = current[splitted[i]]
      for j in 0..<currentNode.len:
        if currentNode[j].kind == nnkExprColonExpr and currentNode[j][0] == newLit(splitted[i]):
          currentNode = currentNode[j][1]
    var fileData = staticRead(getProjectPath() & "/" & file)
    current[splitted[^1]] = newJString(fileData)
    currentNode.add(newNimNode(nnkExprColonExpr).add(newLit(splitted[^1]), newLit(fileData)))

  result.add(obj)


var
  documentation* = docs()
  currentGuidePage* = remember ("0_user_guide", "0_general", "0_introduction.md")


proc getFileText*(rootFolder, folder, filename: string): string =
  try:
    return documentation[rootFolder][folder][filename].getStr
  except:
    return "NOTFOUND"

proc getPrevFile*(rootFolder, folder, filename: string): tuple[a, b, c: string] =
  var
    rootKeys: seq[string] = collect:
      for i in documentation.keys(): i
    rootFolderKeys: seq[string] = collect:
      for i in documentation[rootFolder].keys(): i
    folderKeys: seq[string] = collect:
      for i in documentation[rootFolder][folder].keys(): i
    indexFile = folderKeys.find(filename)
    indexFolder = rootFolderKeys.find(folder)
    indexRoot = rootKeys.find(rootFolder)
    fileResult =
      if indexFile == folderKeys.len-1: 0 else: indexFile+1
    folderResult =
      if indexFolder == rootFolderKeys.len-1:
        0
      elif indexFile == folderKeys.len-1:
        indexFolder+1
      else:
        indexFolder
    rootFolderResult =
      if indexRoot == rootKeys.len-1:
        0
      elif indexFolder == rootFolderKeys.len-1:
        indexRoot+1
      else:
        indexRoot
  (rootKeys[rootFolderResult], rootFolderKeys[folderResult], folderKeys[fileResult])

proc getNextFile*(rootFolder, folder, filename: string): tuple[a, b, c: string] =
  var
    rootKeys: seq[string] = collect:
      for i in documentation.keys(): i
    rootFolderKeys: seq[string] = collect:
      for i in documentation[rootFolder].keys(): i
    folderKeys: seq[string] = collect:
      for i in documentation[rootFolder][folder].keys(): i
    indexFile = folderKeys.find(filename)
    indexFolder = rootFolderKeys.find(folder)
    indexRoot = rootKeys.find(rootFolder)
    fileResult =
      if indexFile == 0:
        folderKeys.len-1
      else:
        indexFile-1
    folderResult =
      if indexFolder == 0:
        rootFolderKeys.len-1
      elif indexFile == folderKeys.len-1:
        indexFolder-1
      else:
        indexFolder
    rootFolderResult =
      if indexRoot == 0:
        rootKeys.len-1
      elif indexFolder == 0:
        indexRoot-1
      else:
        indexRoot
  (rootKeys[rootFolderResult], rootFolderKeys[folderResult], folderKeys[fileResult])


# Declare component
component SideBar:
  isMobile: bool = false
  callback: (proc(a, b, c: string): void) = (proc(a, b, c: string) = discard)

  # Declare HTML template
  `template`:
    tDiv(class =
        if self.isMobile:
          "flex-col xl:flex gap-12 lg:gap-8 xl:gap-4 px-2 h-full"
        else:
          "flex-col hidden xl:flex gap-12 lg:gap-8 xl:gap-4 px-2 pt-8 h-full"
    ):
      if not self.isMobile:
        tP(class = "text-5xl lg:text-3xl xl:text-2xl font-bold text-center w-max"):
          "Documentation 📕"
      tDiv(class = "flex flex-col justify-between gap-16 lg:gap-12 xl:gap-8"):
        tDiv(class = "flex flex-col pl-8 lg:pl-6 xl:pl-4 gap-8 lg:gap-4 xl:gap-2"):
          for title in documentation.keys():
            tP(class = "text-7xl lg:text-2xl xl:text-xl font-bold cursor-pointer select-none"):
              {title.replace(re"^\d+_", "").replace("_", " ").capitalize()}
            nim:
              let folders = documentation[title]
            tDiv(class = "flex flex-col pl-12 lg:pl-8 xl:pl-4"):
              for folder in folders.keys():
                tP(class = "text-5xl lg:text-xl xl:text-lg font-bold cursor-pointer select-none"):
                  {folder.replace(re"^\d+_", "").replace("_", " ").capitalize()}
                tDiv(class = "flex flex-col gap-8 lg:gap-4 xl:gap-2"):
                  for file in folders[folder].keys():
                    tP(
                      class =
                        if currentGuidePage.val == (title, folder, file):
                          fmt"pl-12 lg:pl-8 xl:pl-4 text-4xl lg:text-lg xl:text-base cursor-pointer select-none bg-[{Foreground}]/25 dark:bg-[{ForegroundDark}]/25"
                        else:
                          "pl-12 lg:pl-8 xl:pl-4 text-4xl lg:text-lg xl:text-base cursor-pointer select-none"
                    ):
                      {file.replace(re"^\d+_", "").replace(".md", "").replace("_", " ").capitalize()}
                      @click:
                        self.callback(title, folder, file)
        tDiv(class = "flex"):
          component Button(
            action = proc() =
              {.emit: """//js
              window.open('https://hapticx.github.io/happyx/happyx.html', '_blank').focus();
              """.}
          ):
            "📕 API Docs"
