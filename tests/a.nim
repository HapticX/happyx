type
  AObj = object of RootObj
  ARef = ref AObj

  BObj = object of AObj
  BRef = ref BObj

  CObj = object of AObj
  CRef = ref CObj


func initA(): ARef =
  ARef()

func initB(): BRef =
  BRef()

func initC(): CRef =
  CRef()


method reRender(self: ARef) {.base.} =
  echo "A"

method reRender(self: BRef) =
  echo "B"

method reRender(self: CRef) =
  echo "C"


var x = [initA(), initB(), initC()]

for i in x:
  i.reRender()

