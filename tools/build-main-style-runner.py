"""Prepare a background Studio edit-mode migration and local serialization probe.

Studio does not write the working place. A separate file assembler consumes the
serialized instance buffer only after the native checks pass.
"""
from pathlib import Path
import argparse
import hashlib
import json
ROOT=Path(__file__).resolve().parents[1]
p=argparse.ArgumentParser()
p.add_argument('output_directory',type=Path)
p.add_argument('--verify',action='store_true')
a=p.parse_args()
a.output_directory.mkdir(parents=True,exist_ok=True)
def scoped(path): return 'do\n'+(ROOT/path).read_text(encoding='utf-8')+'\nend\n'
if a.verify:
    parts=['local ok,err=xpcall(function()\nassert(not game:GetService("RunService"):IsRunning())\ntask.wait(8)\n']
    for test in ['tests/style-main-edit.luau','tests/map-edit.luau','tests/combat-edit.luau']:
        parts.append(scoped(test))
    for path in sorted((ROOT/'src/combat').rglob('*.luau'))+[ROOT/'src/client/ExplorerFlight.client.luau']:
        rel=path.relative_to(ROOT/'src/combat').as_posix() if 'combat' in path.parts else 'StarterPlayer/StarterPlayerScripts/ExplorerFlight.client.luau'
        components=rel.split('/')
        name=components[-1].removesuffix('.luau').removesuffix('.client').removesuffix('.server')
        expr='game'
        for component in components[:-1]+[name]: expr+=':FindFirstChild('+json.dumps(component)+')'
        source=path.read_text(encoding='utf-8')
        level=0
        while ']'+('='*level)+']' in source: level+=1
        quote='['+'='*level+'['+source+']'+'='*level+']'
        parts.append('do local obj='+expr+'\nassert(obj and obj.Source=='+quote+',"Installed source differs: '+rel+'") end\n')
    parts.append('print("FINAL_NATIVE_PASS: saved geometry, map, combat installation and 12 source files verified; Play=false")\nend,debug.traceback)\nif not ok then print("FINAL_NATIVE_FAIL "..tostring(err)) end\n')
    target=a.output_directory/'verify-main-style.luau'
    target.write_text('\n'.join(parts),encoding='utf-8')
    print(target)
    raise SystemExit(0)
parts=['local buildOk,buildError=xpcall(function()\nassert(not game:GetService("RunService"):IsRunning(),"Edit mode only")\ntask.wait(8)\n']
parts.append('if not workspace.Map:FindFirstChild("TrainingYard") then\n'+scoped('build-combat.luau')+'end\n')
parts.append(scoped('install-combat.luau'))
parts.append(scoped('install-flight.luau'))
parts.append(scoped('apply-style-main.luau'))
parts.append('''
local paths={
 {workspace.Map,"Workspace"},
 {game.ServerScriptService.Combat,"ServerScriptService"},
 {game.ServerScriptService.CombatBootstrap,"ServerScriptService"},
 {game.ReplicatedStorage.CombatConfig,"ReplicatedStorage"},
 {game.ReplicatedStorage.CombatNet,"ReplicatedStorage"},
 {game.StarterPlayer.StarterPlayerScripts.CombatClient,"StarterPlayer/StarterPlayerScripts"},
 {game.StarterPlayer.StarterPlayerScripts.ExplorerFlight,"StarterPlayer/StarterPlayerScripts"},
}
local roots={}
for _,v in paths do v[1]:SetAttribute("StyleSaveDestination",v[2]) table.insert(roots,v[1]) end
local content=game:GetService("SerializationService"):SerializeInstancesAsync(roots)
local encoded=buffer.tostring(game:GetService("EncodingService"):Base64Encode(content))
print("SAVE_SIZE "..#encoded)
for i=1,#encoded,30000 do print("SAVE_CHUNK "..math.floor((i-1)/30000+1).." "..encoded:sub(i,i+29999)) end
print("SAVE_DONE")
''')
for test in ['tests/map-edit.luau','tests/combat-edit.luau']:
    parts.append('do local ok,err=xpcall(function()\n'+scoped(test)+'\nend,debug.traceback)\nprint("STAGE_TEST",'+repr(test)+',ok,tostring(err)) end\n')
parts.append('end,debug.traceback)\nif not buildOk then print("STYLE_BUILD_FAILED "..tostring(buildError)) end\n')
target=a.output_directory/'run-main-style.luau'
target.write_text('\n'.join(parts),encoding='utf-8')
(a.output_directory/'source-snapshot.json').write_text(json.dumps({str(p.relative_to(ROOT)).replace('\\','/'):hashlib.sha256(p.read_bytes()).hexdigest() for p in (ROOT/'src').rglob('*.luau')},indent=2)+'\n',encoding='utf-8')
print(target)
