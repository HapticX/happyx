echo "Build Python Win Bindings"
cd src
nim c --app:lib --out:../bindings/python/happyx/happyx.pyd --tlsEmulation:off -d:useRealtimeGC --mm:arc -t:-flto -l:-flto --opt:speed -x:off -a:off --passL:-static --threads:off -d:debug -d:httpx -d:export2py happyx
cd ../
