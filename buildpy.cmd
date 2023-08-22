echo "Build Python Win Bindings"
cd src
nim c --app:lib --out:../bindings/python/happyx/happyx.pyd --tlsEmulation:off --passL:-static --passL:-flto --passC:-flto --opt:speed --threads:on -x:off -c:off -w:off -d:debug -d:useMalloc -d:httpx -d:export2py happyx
cd ../
