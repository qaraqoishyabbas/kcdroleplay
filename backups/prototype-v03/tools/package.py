"""Build a self-contained Studio Command Bar installer from the Explorer-shaped sources."""
from pathlib import Path
import json
ROOT=Path(__file__).resolve().parents[1]
def quote(text):
    n=0
    while ']'+'='*n+']' in text: n+=1
    return '['+'='*n+'['+text+']'+'='*n+']'
lines=['assert(not game:GetService("RunService"):IsRunning(),"Stop Play first")',
'local editor=game:GetService("ScriptEditorService")',
'''local function ensure(parent,name,class)
local o=parent:FindFirstChild(name)
if o then assert(o.ClassName==class,"Class mismatch: "..o:GetFullName()) return o end
local n=Instance.new(class) n.Name=name n.Parent=parent return n end''',
'local rs=game:GetService("ReplicatedStorage")',
'ensure(rs,"Shared","Folder")',
'local remotes=ensure(rs,"Remotes","Folder")',
'for _,n in {"InteractionRemote","UIUpdateRemote","CombatRemote","InventoryRemote","TradeRemote"} do ensure(remotes,n,"RemoteEvent") end',
'local ss=game:GetService("ServerStorage")',
'for _,n in {"NPCModels","ItemModels","WeaponModels","WorldTemplates"} do ensure(ss,n,"Folder") end',
'''for _,name in {"MainMenu","HUD","DialogueUI","InventoryUI","TradeUI"} do
local gui=ensure(game:GetService("StarterGui"),name,"ScreenGui")
gui.ResetOnSpawn=false gui.IgnoreGuiInset=false gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
gui.DisplayOrder=name=="MainMenu" and 40 or (name=="DialogueUI" and 35 or (name=="HUD" and 10 or 30))
end''']
manifest=[]
for f in sorted((ROOT/'src').rglob('*.luau')):
    relative=f.relative_to(ROOT/'src')
    parts=list(relative.parts)
    name=parts[-1].removesuffix('.luau')
    cls='ModuleScript'
    if name.endswith('.server'): cls='Script'; name=name.removesuffix('.server')
    elif name.endswith('.client'): cls='LocalScript'; name=name.removesuffix('.client')
    lines.append('do local parent=game:GetService('+json.dumps(parts[0])+')')
    for part in parts[1:-1]:
        if part=='StarterPlayerScripts': lines.append('parent=parent:WaitForChild("StarterPlayerScripts")')
        else: lines.append('parent=ensure(parent,'+json.dumps(part)+',"Folder")')
    lines.append('local obj=ensure(parent,'+json.dumps(name)+','+json.dumps(cls)+')')
    if cls in ('Script','LocalScript'): lines.append('obj.Enabled=false')
    lines.append('local source='+quote(f.read_text()))
    lines.append('editor:UpdateSourceAsync(obj,function() return source end)')
    if cls in ('Script','LocalScript'): lines.append('obj.Enabled=true')
    lines.append('end')
    manifest.append({'file':str(relative),'explorer':'/'.join(parts[:-1]+[name]),'type':cls})
lines.append('print("CROWN_INSTALL_OK",'+str(len(manifest))+',"source files")')
(ROOT/'install-crownlands.luau').write_text('\n'.join(lines)+'\n')
(ROOT/'docs/source-manifest.json').write_text(json.dumps(manifest,indent=2,ensure_ascii=False)+'\n')
print(f'Packaged {len(manifest)} sources; installer {(ROOT/"install-crownlands.luau").stat().st_size} bytes')
