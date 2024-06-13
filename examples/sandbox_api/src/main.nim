# Import HappyX
import
  asyncdispatch,
  algorithm,
  asyncfile,
  osproc,
  os,
  ../../../src/happyx,
  regex


model Task:
  id: string
  code: string


type
  CompileTask = object
    task: Task
    process: Process


var tasks: seq[CompileTask] = @[]

if not dirExists("tasks"):
  createDir("tasks")


regCORS:
  origins: "*"
  headers: "*"
  methods: "*"
  credentials: true


const
  host {.strdefine.} = "127.0.0.1"
  port {.intdefine.} = 5123


serve host, port:
  get "/":
    {.gcsafe.}:
      if not dirExists("website"):
        return %*{"response": "website not compiled"}
      var f = openAsync("website" / "index.html")
      let data = await f.readAll()
      f.close()
      req.answerHtml(data)

  post "/[task:Task]":
    {.gcsafe.}:
      if task.code.len > 2048:
        statusCode = 400
        return %*{
          "response": "error",
          "error_code": 1,
          "error": "code length too long (> 2048)"
        }
      if task.code.contains(
          re2"(macro +\w+|static *: *\n +|\bstaticExec\b|\bgorge\b|\bgorgeEx\b|\bstaticEx\b)"
      ):
        statusCode = 400
        return %*{
          "response": "error",
          "error_code": 10,
          "error": "Sorry, but code shouldn't contains any macros or static statements"
        }
      var f = openAsync("tasks" / (task.id & ".nim"), fmWrite)
      await f.write(task.code)
      f.close()
      tasks.add(CompileTask(
        task: task,
        process: startProcess(
          "nim", getCurrentDir(), @[
            "js", "-d:release", "--opt:size", "--out:" & ("tasks" / (task.id & ".js")),
            "tasks" / (task.id & ".nim")
          ], options = {poStdErrToStdOut, poUsePath}
        )
      ))
      return %*{"response": task.id}
  
  get "/task/{taskId}/code":
    {.gcsafe.}:
      for file in "tasks".walkDirRec(relative = true):
        if taskId in file and file.endsWith(".nim"):
          var
            f = openAsync("tasks" / file, fmRead)
            d = await f.readAll()
          f.close()
          return %*{"response": d}
      return %*{"response": false}
  
  get "/task/{taskId}/completed":
    {.gcsafe.}:
      var
        task: CompileTask
        found = false
      for t in tasks:
        if t.task.id == taskId:
          task = t
          found = true
          break
      if found and task.process.hasData:
        var output = ""
        if task.process.hasData:
          for line in task.process.lines:
            # clear console output
            var l = line
            for m in l.findAll(re2("(\\S+?(" & taskId & ".(nim|js)(\\(\\d+ *, *\\d+\\))?))")):
              l = l.replace(l[m.group(0)], l[m.group(1)])
              l = l.replace(taskId, "main")
            for m in l.findAll(re2("([a-zA-Z]:\\\\([^\n]+))")):
              var splitted = l[m.group(0)].split(re2"(\\|/)").reversed()
              if splitted.len > 3:
                splitted = splitted[0..2]
              l = l.replace(l[m.group(0)], splitted.reversed().join("/"))
            output.add l
            output.add "\n"
        task.process.close()
        var data =
          if fileExists("tasks" / (task.task.id & ".js")):
            var
              f = openAsync("tasks" / (task.task.id & ".js"))
              d = await f.readAll()
            f.close()
            removeFile("tasks" / (task.task.id & ".js"))
            d
          else:
            ""
        tasks.delete(tasks.find(task))
        return %*{"response": {
          "output": output,
          "js": data
        }}
      return %*{"response": false}
  
  get "/tasklist":
    {.gcsafe.}:
      var response = %*{"response": []}
      for t in tasks:
        response.add newJString(t.task.id)
  
  middleware:
    {.gcsafe.}:
      if req.body.len > 4096:
        statusCode = 400
        return %*{
          "response": "error",
          "error_code": 3,
          "error": "request length too long (> 4096)"
        }
  
  get "/{file:path}":
    echo file
    echo "website" / file
    var p = "website" / file
    if fileExists(p):
      var f = openAsync(p, fmRead)
      let data = await f.readAll()
      f.close()
      return data
    p = "website" / "happyx" / file
    if fileExists(p):
      var f = openAsync(p, fmRead)
      let data = await f.readAll()
      f.close()
      return data
    p = "website" / "public" / file
    if fileExists(p):
      var f = openAsync(p, fmRead)
      let data = await f.readAll()
      f.close()
      return data
    p = "website" / "happyx" / "public" / file
    if fileExists(p):
      var f = openAsync(p, fmRead)
      let data = await f.readAll()
      f.close()
      return data
    return ""
