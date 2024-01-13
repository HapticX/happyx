echo "Build Python Win Bindings"
cd src
nim c --app:lib --out:../bindings/python/happyx/happyx.pyd -d:useRealtimeGC --mm:arc --tlsEmulation:off --passL:-static --threads:off -d:debug -d:httpx -d:export2py happyx
nim c --app:lib --out:../bindings/python/happyx/happyx_threaded.pyd -d:useRealtimeGC --mm:arc --tlsEmulation:off --passL:-static --threads:on -d:debug -d:httpx -d:export2py happyx
nim c --app:lib --out:../bindings/python/happyx/happyx_threaded_no_realtime.pyd --mm:arc --tlsEmulation:off --passL:-static --threads:on -d:debug -d:httpx -d:export2py happyx
nim c --app:lib --out:../bindings/python/happyx/happyx_no_realtime.pyd --mm:arc --tlsEmulation:off --passL:-static --threads:off -d:debug -d:httpx -d:export2py happyx
cd ../
