const
  textBody = "Hello, world!"
  jsonBody = "{\"message\":\"Hello, world!\"}"

when defined(benchHappyX):
  import ../src/happyx

  const benchPort {.intdefine.} = 5000

  serve("127.0.0.1", benchPort):
    get "/":
      textBody

    get "/json":
      jsonBody

elif defined(benchJester):
  import jester

  const benchPort {.intdefine.} = 5001

  settings:
    bindAddr = "127.0.0.1"
    port = Port(benchPort)

  routes:
    get "/":
      resp textBody

    get "/json":
      resp jsonBody

  runForever()

elif defined(benchPrologue):
  import prologue

  const benchPort {.intdefine.} = 5002

  proc hello(ctx: Context) {.async.} =
    resp textBody

  proc helloJson(ctx: Context) {.async.} =
    resp jsonBody

  let settings = newSettings(
    appName = "HappyX benchmark - Prologue",
    address = "127.0.0.1",
    port = Port(benchPort),
    debug = false,
  )
  var app = newApp(settings = settings)
  app.get("/", hello)
  app.get("/json", helloJson)
  app.run()

elif defined(benchGuildenstern):
  when defined(posix):
    import guildenstern/[dispatcher, httpserver]

    const benchPort {.intdefine.} = 5003

    let server = newHttpServer(proc() =
      if isUri("/json"):
        reply jsonBody
      else:
        reply textBody
    )
    if server.start(benchPort):
      joinThread(server.thread)
    else:
      quit("Failed to start Guildenstern benchmark server", QuitFailure)
  else:
    {.error: "Guildenstern supports POSIX-like platforms only.".}

elif defined(benchMike):
  import mike

  const benchPort {.intdefine.} = 5004

  "/" -> get:
    ctx.send textBody

  "/json" -> get:
    ctx.send jsonBody

  run(benchPort)

elif defined(benchWhip):
  import
    whip,
    sugar

  const benchPort {.intdefine.} = 5005

  let app = initWhip()
  app.onGet "/", (w: Wreq) => w.send(textBody)
  app.onGet "/json", (w: Wreq) => w.json(jsonBody)
  app.start(benchPort)

else:
  import
    benchy,
    std/[httpclient, net, os, osproc, strformat, strutils, times]

  const
    warmupRequests {.intdefine.} = 200
    serverStartTimeoutMs {.intdefine.} = 60_000
    clientReuseLimit {.intdefine.} = 100
    requestBatchSizes = [100, 1000, 10000]

  type BenchmarkTarget = object
    name: string
    define: string
    port: int

  type BenchmarkEndpoint = object
    name: string
    path: string
    expectedBody: string

  const allBenchmarkTargets = [
    BenchmarkTarget(name: "HappyX", define: "benchHappyX", port: 5000),
    BenchmarkTarget(name: "Jester", define: "benchJester", port: 5001),
    BenchmarkTarget(name: "Mike", define: "benchMike", port: 5004),
    BenchmarkTarget(name: "Prologue", define: "benchPrologue", port: 5002),
    BenchmarkTarget(name: "Guildenstern", define: "benchGuildenstern", port: 5003),
    BenchmarkTarget(name: "Whip", define: "benchWhip", port: 5005),
  ]

  const benchmarkEndpoints = [
    BenchmarkEndpoint(name: "text", path: "/", expectedBody: textBody),
    BenchmarkEndpoint(name: "json", path: "/json", expectedBody: jsonBody),
  ]

  proc benchmarkTargetsForPlatform(): seq[BenchmarkTarget] =
    for target in allBenchmarkTargets:
      when not defined(posix):
        if target.define == "benchGuildenstern":
          continue
      when NimMajor >= 2:
        if target.define == "benchWhip":
          continue
      result.add target

  proc sourcePath(): string =
    for candidate in [
      getCurrentDir() / "tests" / "benchmark.nim",
      getCurrentDir() / "benchmark.nim",
      currentSourcePath(),
    ]:
      if fileExists(candidate):
        return candidate
    quit("Cannot locate tests/benchmark.nim source file.", QuitFailure)

  proc executablePath(target: BenchmarkTarget): string =
    getTempDir() / fmt"happyx-bench-{target.name.toLowerAscii()}{ExeExt}"

  proc compileFlags(): seq[string] =
    result = @[
      "-d:danger",
      "-d:strip",
      "--hints:off",
      "--warnings:off",
    ]
    when defined(posix):
      result.add "-d:lto"

  proc compileServer(target: BenchmarkTarget, source, output: string): bool =
    var args = @["nim", "c"] & compileFlags() & @[
      fmt"-d:{target.define}",
      fmt"-d:benchPort={target.port}",
      fmt"--out:{output}",
      source,
    ]
    let (compileOutput, exitCode) = execCmdEx(quoteShellCommand(args))
    if exitCode == QuitSuccess:
      return true

    echo ""
    echo fmt"Skipping {target.name}: server failed to compile."
    let trimmed = compileOutput.strip()
    if trimmed.len > 0:
      echo trimmed
    false

  proc isPortInUse(port: int): bool =
    var socket = newSocket()
    result = false
    try:
      socket.connect("127.0.0.1", Port(port))
      result = true
    except CatchableError:
      discard
    finally:
      socket.close()

  proc stopLeftoverServer(target: BenchmarkTarget) =
    let output = executablePath(target)
    when defined(windows):
      let exeName = splitPath(output).tail
      discard execCmdEx(quoteShellCommand(@["taskkill", "/F", "/IM", exeName]))
    else:
      discard execCmdEx(quoteShellCommand(@["pkill", "-f", splitPath(output).tail]))
    if isPortInUse(target.port):
      sleep(500)

  proc stopBenchmarkProcess(process: var Process; target: BenchmarkTarget) =
    let output = executablePath(target)
    if process.running:
      try:
        process.terminate()
      except CatchableError:
        discard
      if process.waitForExit(3000) < 0:
        try:
          process.kill()
        except CatchableError:
          discard
        discard process.waitForExit(2000)
    try:
      process.close()
    except CatchableError:
      discard
    when defined(windows):
      let exeName = splitPath(output).tail
      discard execCmdEx(quoteShellCommand(@["taskkill", "/F", "/IM", exeName]))
    else:
      discard execCmdEx(quoteShellCommand(@["pkill", "-f", splitPath(output).tail]))
    while isPortInUse(target.port):
      sleep(200)

  proc requestOnce(url, expectedBody: string) =
    var client = newHttpClient(timeout = 1000)
    try:
      let body = client.getContent(url)
      if body != expectedBody:
        raise newException(ValueError, fmt"Unexpected response: {body}")
    finally:
      client.close()

  proc waitForServer(target: BenchmarkTarget): bool =
    let
      url = fmt"http://127.0.0.1:{target.port}/"
      deadline = epochTime() + serverStartTimeoutMs.float / 1000.0
    while epochTime() < deadline:
      try:
        requestOnce(url, textBody)
        return true
      except CatchableError:
        sleep(100)
    false

  proc runRequests(url, expectedBody: string, count: int) =
    var remaining = count
    while remaining > 0:
      let chunkSize = min(remaining, clientReuseLimit)
      var client = newHttpClient(timeout = 5000)
      try:
        for _ in 0 ..< chunkSize:
          let body = client.getContent(url)
          if body != expectedBody:
            raise newException(ValueError, fmt"Unexpected response: {body}")
      finally:
        client.close()
      if remaining > chunkSize:
        sleep(1)
      remaining -= chunkSize

  proc benchmarkTarget(target: BenchmarkTarget, source: string) =
    let output = executablePath(target)
    if not compileServer(target, source, output):
      return

    stopLeftoverServer(target)
    if isPortInUse(target.port):
      echo ""
      echo fmt"Skipping {target.name}: port {target.port} is already in use."
      echo fmt"Stop the process listening on 127.0.0.1:{target.port} and retry."
      return

    echo ""
    echo fmt"Starting {target.name} on http://127.0.0.1:{target.port}/"
    var process = startProcess(output, options = {poParentStreams, poUsePath})
    try:
      if not waitForServer(target):
        echo fmt"Skipping {target.name}: server did not start within {serverStartTimeoutMs} ms."
        return

      for endpoint in benchmarkEndpoints:
        let url = fmt"http://127.0.0.1:{target.port}{endpoint.path}"
        try:
          runRequests(url, endpoint.expectedBody, warmupRequests)
          for requestBatchSize in requestBatchSizes:
            timeIt fmt"{target.name} {endpoint.name} ({requestBatchSize} sequential GET {endpoint.path} requests)":
              runRequests(url, endpoint.expectedBody, requestBatchSize)
        except CatchableError as e:
          echo fmt"Skipping {target.name} {endpoint.name}: {e.msg}"
          return
    finally:
      stopBenchmarkProcess(process, target)
      sleep(2000)

  when isMainModule:
    let targets = benchmarkTargetsForPlatform()

    echo "HappyX framework benchmark"
    echo "Request batch sizes: ", requestBatchSizes.join(", ")
    echo fmt"Warmup requests per framework: {warmupRequests}"
    echo fmt"Client connection reuse limit: {clientReuseLimit}"
    echo ""
    echo "Install optional dependencies with:"
    echo "nimble install benchy jester prologue guildenstern mike whip"
    when not defined(posix):
      echo "Note: Guildenstern is POSIX-only and is skipped on this platform."
    when NimMajor >= 2:
      echo "Note: Whip is skipped on Nim 2.x (packedjson dependency is incompatible)."
    echo ""

    let source = sourcePath()
    for target in targets:
      benchmarkTarget(target, source)
