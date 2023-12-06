cd src

nim c ^
  -d:noSignalHandler ^
  -d:export2jvm ^
  -d:release ^
  -d:httpx ^
  --tlsEmulation:off ^
  --app:lib ^
  --threads:on ^
  --panics:off ^
  --checks:off ^
  --assertions:off ^
  --opt:speed ^
  --gc:arc ^
  --mm:arc ^
  --out:../bindings/java/src/main/resources/happyx.dll ^
  happyx.nim

cd ..
