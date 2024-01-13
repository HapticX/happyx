echo "Build Python Win Bindings"
cd src
nim c --app:lib --out:../bindings/python/happyx/happyx.pyd                      --tlsEmulation:off --mm:arc --passL:-static --threads:off --opt:speed -t:-flto -l:-flto -x:off -a:off -d:useRealtimeGC -d:release -d:happyxDebug -d:httpx -d:export2py happyx
nim c --app:lib --out:../bindings/python/happyx/happyx_threaded.pyd             --tlsEmulation:off --mm:arc --passL:-static --threads:on  --opt:speed -t:-flto -l:-flto -x:off -a:off -d:useRealtimeGC -d:release -d:happyxDebug -d:httpx -d:export2py happyx
nim c --app:lib --out:../bindings/python/happyx/happyx_threaded_no_realtime.pyd --tlsEmulation:off --mm:arc --passL:-static --threads:on  --opt:speed -t:-flto -l:-flto -x:off -a:off -d:release -d:happyxDebug -d:httpx -d:export2py happyx
nim c --app:lib --out:../bindings/python/happyx/happyx_no_realtime.pyd          --tlsEmulation:off --mm:arc --passL:-static --threads:off --opt:speed -t:-flto -l:-flto -x:off -a:off -d:release -d:happyxDebug -d:httpx -d:export2py happyx
cd ../
