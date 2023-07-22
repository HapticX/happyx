## # UI Enums ⚙
## 
## Describes all built-in UI enums
## 

type
  Alignment* {.size: sizeof(int8), final, pure.} = enum
    aStart,
    aCenter,
    aEnd
  ToolTipMode* {.size: sizeof(int8), final, pure.} = enum
    ttSuccess,
    ttError,
    ttWarning,
    ttInfo
