echo "Build Python Win Bindings"
cd src
nim c --app:lib --out:../bindings/python/happyxpy/happyx_win.pyd -d:useRealtimeGC --mm:arc --tlsEmulation:off --passL:-static --threads:off -d:debug -d:httpx -d:export2py happyx
cd ../
