echo "Build Python Win Bindings"
cd src
nim c --app:lib --out:../bindings/python/happyx/happyx.pyd --tlsEmulation:off --passL:-static -t:-flto -l:-flto --opt:speed --threads:on -x:off -c:off -d:debug -d:useMalloc -d:httpx --gc:orc -d:export2py happyx
cd ../
