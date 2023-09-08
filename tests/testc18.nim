import ../src/happyx
import times
import std/jsonutils


# json serialize DateTime
proc toJsonHook(dt: DateTime, opt = initToJsonOptions()): JsonNode =
  newJString($dt)

# json deserialize DateTime
proc initFromJson(dt: var DateTime, jsonNode: JsonNode, jsonPath: var string) =
  dt = parse(jsonNode.getStr, initTimeFormat("yyyy-MM-dd HH:mm:ss"))


model FighterCreate:
  name: string
  skill: string
  test: seq[string]
  createdAt: DateTime


serve "127.0.0.1", 5000:
  post "/fighter[o:FighterCreate:json]":
    echo "new fighter: ", o
    return {"response": {
      "name": o.name,
      "skill": o.skill,
      "test": o.test,
      "createdAt": $o.createdAt
    }}
  get "/fighter/{name:string}":
    echo name
