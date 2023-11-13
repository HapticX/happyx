echo "Build Python Win Bindings"
cd src
nim c --app:lib --out:../bindings/python/happyx/happyx.pyd --tlsEmulation:off -t:-flto -l:-flto --opt:speed -d:ssl --passL:-static --threads:off -d:debug -d:httpx -d:export2py happyx
cd ../
