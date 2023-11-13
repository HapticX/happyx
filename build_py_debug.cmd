echo "Build Python Win Bindings"
cd src
nim c --app:lib --out:../bindings/python/happyx/happyx.pyd --tlsEmulation:off --passL:-static --threads:off -x:off -c:off -d:debug -d:httpx -d:export2py happyx
cd ../
