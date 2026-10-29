"""Repeatable offline checks; reads RPG sources and never starts Roblox/Studio.

Run with Python 3.11+; requires the official Luau CLI on PATH or LUAU_CLI_DIR.
All generated bundles and logs are saved under test-results/offline.
"""
from pathlib import Path
import concurrent.futures
import hashlib
import json
import os
import re
import shutil
import subprocess
import sys
import urllib.request
import xml.etree.ElementTree as ET

HERE = Path(__file__).resolve().parent
WORK = HERE.parents[1]
PROJECT = Path(sys.argv[1]).resolve() if len(sys.argv) > 1 else WORK
OUT = Path(sys.argv[2]) if len(sys.argv) > 2 else WORK / 'test-results' / 'offline'
OUT.mkdir(parents=True, exist_ok=True)
CLI = Path(os.environ['LUAU_CLI_DIR']) if os.environ.get('LUAU_CLI_DIR') else None
def executable(name):
    if CLI:
        for suffix in ('.exe', ''):
            path = CLI / (name + suffix)
            if path.is_file(): return str(path)
    path = shutil.which(name) or shutil.which(name + '.exe')
    if path: return path
    raise SystemExit(f'{name} missing: install the official Luau CLI and set LUAU_CLI_DIR or PATH')
COMPILE = executable('luau-compile')
LUAU = executable('luau')

def read(path):
    return path.read_text(encoding='utf-8-sig')

active = sorted((PROJECT / 'src').rglob('*.luau')) + sorted(PROJECT.glob('*.luau'))
active += sorted((PROJECT / 'tests').glob('*.luau')) + sorted((PROJECT / 'tools').glob('*.luau'))
before = {str(p.relative_to(PROJECT)): hashlib.sha256(p.read_bytes()).hexdigest() for p in active}
plugin = PROJECT / 'hermes-combat-plugin.rbxmx'
plugin_source = ET.parse(plugin).find('.//ProtectedString[@name="Source"]').text
(OUT / 'plugin-source.luau').write_text(plugin_source, encoding='utf-8')
compile_results = []
for path in active + [OUT / 'plugin-source.luau']:
    result = subprocess.run([COMPILE, '--null', str(path)], capture_output=True, text=True, encoding='utf-8')
    compile_results.append({'file': str(path), 'passed': result.returncode == 0, 'output': result.stdout + result.stderr})
(OUT / 'compile.json').write_text(json.dumps(compile_results, indent=2, ensure_ascii=False), encoding='utf-8')
print('COMPILE', sum(r['passed'] for r in compile_results), '/', len(compile_results))

factories = []
for path in sorted((PROJECT / 'src' / 'combat').rglob('*.luau')) + [PROJECT / 'src/client/ExplorerFlight.client.luau', PROJECT / 'build-combat.luau', PROJECT / 'tools/optimize-map.luau']:
    name = path.name.removesuffix('.luau').removesuffix('.client').removesuffix('.server')
    factories.append(f'factories[{json.dumps(name)}] = function()\n{read(path)}\nend\n')
    if name == 'optimize-map':
        for profile in ('low','restore'):
            source=read(path).replace('local PROFILE = "balanced"',f'local PROFILE = "{profile}"')
            factories.append(f'factories["optimize-map-{profile}"] = function()\n{source}\nend\n')
bundle = read(HERE / 'mock-roblox.luau') + '\n' + '\n'.join(factories) + '\n' + read(HERE / 'cases.luau')
(OUT / 'behavior-bundle.luau').write_text(bundle, encoding='utf-8')
run = subprocess.run([LUAU, str(OUT / 'behavior-bundle.luau')], capture_output=True, text=True, encoding='utf-8', timeout=45)
(OUT / 'behavior.log').write_text(run.stdout + run.stderr, encoding='utf-8')
behavior = []
for line in run.stdout.splitlines():
    parts = line.split('\t', 2)
    if parts[0] in ('PASS', 'FAIL'):
        behavior.append({'name': parts[1], 'passed': parts[0] == 'PASS', 'error': parts[2] if len(parts) > 2 else None})
    if parts[0] in ('FAIL', 'SUMMARY'):
        print(line)
if run.returncode:
    print('LUAU_RUNTIME_ERROR', run.stderr)

static = []
def check(name, condition, detail=''):
    static.append({'name': name, 'passed': bool(condition), 'detail': detail})
    print(('PASS' if condition else 'FAIL') + '\t' + name + ('\t' + detail if detail else ''))

installer = read(PROJECT / 'install-combat.luau')
sources = sorted((PROJECT / 'src' / 'combat').rglob('*.luau'))
check('all combat sources embedded verbatim in installer', all(read(p) in installer for p in sources), f'{len(sources)} source files')
indented_installer = '\n'.join('\t' + line if line.strip() else line for line in installer.splitlines())
indented_builder = '\n'.join('\t' + line if line.strip() else line for line in read(PROJECT / 'build-combat.luau').splitlines())
check('plugin embeds current installer and builder', indented_installer in plugin_source and indented_builder in plugin_source)
check('plugin never downgrades a newer combat build', 'currentBuild() >= BUILD_ID' in plugin_source)
manifest = json.loads(read(PROJECT / 'docs/combat-manifest.json'))
check('combat manifest covers every source', len(manifest) == len(sources) and {x['file'].replace('\\','/') for x in manifest} == {p.relative_to(PROJECT / 'src/combat').as_posix() for p in sources})
build_id = int(re.search(r'^BUILD_ID\s*=\s*(\d+)', read(PROJECT / 'tools/package-combat.py'), re.M)[1])
test_id = int(re.search(r'InstalledBuild"\)\s*==\s*(\d+)', read(PROJECT / 'tests/combat-edit.luau'))[1])
check('existing combat test expects installed build', build_id == test_id, f'installer={build_id}; test={test_id}')
map_test = read(PROJECT / 'tests/map-edit.luau')
check('existing map test accepts combat installation', 'check(scripts==1' not in map_test, 'map test supports exploration and installed combat')
flight_installer = read(PROJECT / 'install-flight.luau')
check('flight installer embeds current controller', read(PROJECT / 'src/client/ExplorerFlight.client.luau').rstrip() in flight_installer)

# Validate used enum names against the official Roblox creator-docs repository.
enum_pattern = re.compile(r'Enum\.(\w+)\.(\w+)')
uses = [(p, *m.groups()) for p in active for m in enum_pattern.finditer(read(p))]
cache = OUT / 'enum-reference'
cache.mkdir(exist_ok=True)
def enum_reference(name):
    path = cache / (name + '.yaml')
    if not path.exists():
        url = f'https://raw.githubusercontent.com/Roblox/creator-docs/main/content/en-us/reference/engine/enums/{name}.yaml'
        request = urllib.request.Request(url, headers={'User-Agent': 'Crownlands-offline-tests'})
        with urllib.request.urlopen(request, timeout=30) as response:
            path.write_bytes(response.read())
    return name, set(re.findall(r'^\s+-\s+name:\s*(\w+)', read(path), re.M))
enum_errors=[]
try:
    with concurrent.futures.ThreadPoolExecutor(max_workers=6) as pool:
        enums = dict(pool.map(enum_reference, sorted({name for _, name, _ in uses})))
    for path,name,member in uses:
        if member not in enums[name]:
            enum_errors.append(f'{path.relative_to(PROJECT)}: Enum.{name}.{member}')
    check('all enum members exist in official Roblox reference', not enum_errors, f'{len(uses)} uses; {len(enums)} enum types; {len(enum_errors)} errors')
except Exception as error:
    static.append({'name': 'enum reference retrieval', 'passed': None, 'detail': str(error)})
    print('INCOMPLETE enum reference:', error)

after = {str(p.relative_to(PROJECT)): hashlib.sha256(p.read_bytes()).hexdigest() for p in active}
check('project Luau sources unchanged during tests', before == after)
report = {'project':str(PROJECT),'luau_release':'0.743','mode':'offline; no Roblox game session', 'compile':compile_results,'behavior':behavior,'static':static,'enum_errors':enum_errors,'runtime_exit_code':run.returncode,'source_sha256':before}
(OUT / 'results.json').write_text(json.dumps(report, indent=2, ensure_ascii=False), encoding='utf-8')
print('RESULTS', OUT / 'results.json')
sys.exit(1 if run.returncode or any(not r['passed'] for r in compile_results + behavior) or any(r['passed'] is False for r in static) else 0)
