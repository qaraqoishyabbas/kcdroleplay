"""Build an isolated, script-free Roblox art pilot from the approved palette.

No place, terrain, plugin, or combat source is read or modified. The rbxlx is a
separate edit-mode review document; the rbxmx contains only the reference model.
Uses Python's standard library; no network, texture uploads, or paid assets.
"""
from pathlib import Path
from copy import deepcopy
from collections import Counter
import base64
import hashlib
import json
import math
import struct
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'art-pilot'
SPEC = json.loads((ROOT/'docs/art-direction-v0.1.json').read_text(encoding='utf-8'))
MATS = {m['id']: m for m in SPEC['materials']}
ENUM = {'Plaster':2310, 'Wood':512, 'WoodPlanks':528, 'Cobblestone':880,
        'ClayRoofTiles':2307, 'RoofShingles':2308, 'Leather':2309,
        'Fabric':1312, 'Metal':1088, 'Ground':1360, 'Grass':1280}
IDENTITY = (1,0,0, 0,1,0, 0,0,1)
serial = 0
records = []
buildings = []

def prop(item, kind, name, value):
    props = item.find('Properties')
    old = props.find(f"*[@name='{name}']")
    if old is not None: props.remove(old)
    p = ET.SubElement(props, kind, name=name)
    if kind in ('Vector3', 'Color3'):
        for key, v in zip(('X','Y','Z') if kind=='Vector3' else ('R','G','B'), value):
            ET.SubElement(p, key).text = f'{v:.9g}'
    elif kind == 'CoordinateFrame':
        pos, rot = value
        for key, v in zip(('X','Y','Z'), pos): ET.SubElement(p, key).text=f'{v:.9g}'
        for i, v in enumerate(rot): ET.SubElement(p, f'R{i//3}{i%3}').text=f'{v:.9g}'
    elif kind == 'bool': p.text = 'true' if value else 'false'
    elif kind == 'Content': ET.SubElement(p, 'url').text = str(value)
    else: p.text = str(value)
    return p

def attrs(item, **values):
    def s(v):
        b = str(v).encode('utf-8')
        return struct.pack('<I', len(b))+b
    data = struct.pack('<I',len(values))
    for k,v in values.items(): data += s(k)+b'\x02'+s(v)
    prop(item, 'BinaryString', 'AttributesSerialize', base64.b64encode(data).decode())

def item(parent, cls, name):
    global serial
    serial += 1
    obj = ET.SubElement(parent,'Item',{'class':cls,'referent':f'RBX{serial:08d}'})
    ET.SubElement(obj,'Properties')
    prop(obj,'string','Name',name)
    return obj

def model(parent, name, role):
    m = item(parent, 'Model', name)
    prop(m,'token','ModelStreamingMode',1)
    attrs(m, ArtDirectionVersion='0.1', Style='A', Role=role)
    return m

def mm(a,b):
    return tuple(sum(a[i*3+k]*b[k*3+j] for k in range(3)) for i in range(3) for j in range(3))

def mv(a,v): return tuple(sum(a[i*3+j]*v[j] for j in range(3)) for i in range(3))
def add(a,b): return tuple(x+y for x,y in zip(a,b))
def ry(t): return (math.cos(t),0,math.sin(t), 0,1,0, -math.sin(t),0,math.cos(t))
def rz(t): return (math.cos(t),-math.sin(t),0, math.sin(t),math.cos(t),0, 0,0,1)
def rx(t): return (1,0,0, 0,math.cos(t),-math.sin(t), 0,math.sin(t),math.cos(t))

def part(parent, name, size, pos, material, rot=IDENTITY, frame=None,
         cls='Part', shape=1, collide=False, shadow=True, tint=None):
    assert material in MATS and all(0 < s < 1000 for s in size), (name,size)
    if frame:
        origin, orient = frame
        pos,rot = add(origin,mv(orient,pos)),mm(orient,rot)
    obj = item(parent,cls,f'{material}_{name}')
    prop(obj,'Vector3','size',size)
    prop(obj,'CoordinateFrame','CFrame',(pos,rot))
    prop(obj,'bool','Anchored',True)
    prop(obj,'bool','CanCollide',collide)
    prop(obj,'bool','CanTouch',False)
    prop(obj,'bool','CanQuery',collide)
    prop(obj,'bool','CastShadow',shadow)
    prop(obj,'token','TopSurface',0)
    prop(obj,'token','BottomSurface',0)
    prop(obj,'token','Material',ENUM[MATS[material]['pilotMaterial']])
    h = tint or MATS[material]['hex']
    rgb=tuple(int(h.lstrip('#')[i:i+2],16) for i in (0,2,4))
    prop(obj,'Color3uint8','Color3uint8',0xFF000000 | rgb[0]<<16 | rgb[1]<<8 | rgb[2])
    if cls == 'Part': prop(obj,'token','shape',shape)
    attrs(obj, DesignMaterial=material, TextureStage='BuiltinPreview')
    records.append({'name':f'{material}_{name}','material':material,'size':size,'position':pos,
                    'rotation':rot,'class':cls,'role':parent.find("Properties/string[@name='Name']").text})
    return obj

def block(*a, **kw): return part(*a, **kw)

def front_window(parent, frame, center, side=False):
    local = (center,ry(math.pi/2) if side else IDENTITY)
    origin,orient=frame
    wf = (add(origin,mv(orient,local[0])),mm(orient,local[1]))
    block(parent,'WindowRecess',(3.2,3.8,.12),(0,0,0),'M09',frame=wf,shadow=False,tint='#343D35')
    for x in (-1.7,1.7):
        block(parent,'WindowJamb',(.24,4.1,.3),(x,0,.05),'M02',frame=wf)
        block(parent,'OpenShutter',(1.1,3.6,.22),(x*1.4,0,.05),'M03',frame=wf)
    for y in (-2,2): block(parent,'WindowFrame',(3.65,.24,.35),(0,y,.08),'M02',frame=wf)
    block(parent,'WindowMullion',(.15,3.8,.23),(0,0,.1),'M02',frame=wf,shadow=False)
    block(parent,'WindowTransom',(3.2,.15,.23),(0,.2,.1),'M02',frame=wf,shadow=False)

def house(parent, name, origin, w, d, floors, roof_material, yaw=0, canopy=False):
    m = model(parent,name,'BuildingReference')
    frame=(origin,ry(math.radians(yaw)))
    wall_top = 11.8 if floors == 1 else 21.0
    theta=math.radians(43)
    eave=1.15
    half=w/2
    rise=half*math.tan(theta)
    ridge=wall_top+rise+.08
    attrs(m, ArtDirectionVersion='0.1', Style='A', Role='BuildingReference',
          Width=w, Depth=d, WallTop=wall_top, RoofRise=rise, RoofPitchDegrees=43)
    block(m,'Foundation',(w+1,.7,d+1),(0,.35,0),'M04',frame=frame,collide=True)
    # Solid rear/side walls; split front wall leaves a real doorway in the shell.
    stone_h=3.4
    for sy,height,mid in ((.7+stone_h/2,stone_h,'M04'),
                          ((.7+stone_h+wall_top)/2,wall_top-.7-stone_h,'M01')):
        block(m,'RearWall',(w,height,.55),(0,sy,-d/2),'M04' if mid=='M04' else 'M01',frame=frame,collide=True)
        for side in (-1,1):
            block(m,'SideWall',(.55,height,d),(side*w/2,sy,0),mid,frame=frame,collide=True)
    door_width=3.7
    for side in (-1,1):
        panel_w=(w-door_width)/2
        for bottom,top,mid in ((.7,4.1,'M04'),(4.1,wall_top,'M01')):
            block(m,'FrontWall',(panel_w,top-bottom,.55),
                  (side*(door_width/2+panel_w/2),(top+bottom)/2,d/2),mid,frame=frame,collide=True)
        block(m,'CornerPost',(.5,wall_top,.65),(side*(half-.25),wall_top/2,d/2+.1),'M02',frame=frame)
        block(m,'RearCornerPost',(.5,wall_top,.65),(side*(half-.25),wall_top/2,-d/2-.05),'M02',frame=frame)
    block(m,'DoorHeaderFill',(door_width,wall_top-7.9,.55),(0,(wall_top+7.9)/2,d/2),'M01',frame=frame,collide=True)
    for y in (.9,wall_top-.2,11.0) if floors==2 else (.9,wall_top-.2):
        block(m,'FrontStoreyBeam',(w+.3,.42,.7),(0,y,d/2+.1),'M02',frame=frame)
        for side in (-1,1): block(m,'SideStoreyBeam',(.7,.42,d),(side*half,y,0),'M02',frame=frame)
    block(m,'Door',(3.5,7.0,.27),(0,4.2,d/2+.2),'M03',frame=frame,collide=True)
    for side in (-1,1): block(m,'DoorJamb',(.35,7.6,.45),(side*2,4.1,d/2+.27),'M02',frame=frame)
    block(m,'DoorLintel',(4.35,.45,.48),(0,7.95,d/2+.27),'M02',frame=frame)
    for y in (2.4,6.0): block(m,'DoorHinge',(1.1,.16,.12),(-1.05,y,d/2+.39),'M09',frame=frame,shadow=False)
    block(m,'DoorHandle',(.18,.4,.16),(.95,4.2,d/2+.41),'M09',frame=frame,shadow=False)
    block(m,'EntryStep',(5,.3,1.7),(0,.35,d/2+1),'M04',frame=frame,collide=True)
    heights=(6.8,16.2) if floors==2 else (6.6,)
    for y in heights:
        for side in (-1,1): front_window(m,frame,(side*w*.29,y,d/2+.37))
        front_window(m,frame,(half+.37,y,0),True)
    # WedgePart's high face is local +Z. Both high faces point INWARD.
    # The old map pointed them outward, producing the roof's visible "horns".
    for z in (-d/2,d/2):
        for side in (-1,1):
            block(m,'ClosedGable',(.42,rise,half),(side*half/2,wall_top+rise/2,z),
                  'M01',rot=ry(-side*math.pi/2),frame=frame,cls='WedgePart')
        block(m,'GableKingPost',(.4,rise,.6),(0,wall_top+rise/2,z+.1),'M02',frame=frame)
    thickness=.32
    a=half+eave
    length=a/math.cos(theta)
    for side in (-1,1):
        normal=(side*math.sin(theta),math.cos(theta),0)
        center=(side*a/2+normal[0]*thickness/2,
                ridge-a*math.tan(theta)/2+normal[1]*thickness/2,0)
        block(m,'RoofSlope_Left' if side<0 else 'RoofSlope_Right',
              (length,thickness,d+2*eave),center,roof_material,
              rot=rz(-side*theta),frame=frame,collide=True)
        for z in (-d/2-eave-.02,d/2+eave+.02):
            block(m,'RoofFascia',(length,.38,.38),(side*a/2,ridge-a*math.tan(theta)/2-.12,z),
                  'M02',rot=rz(-side*theta),frame=frame)
    block(m,'RidgeCap',(.57,.38,d+2*eave+.12),(0,ridge+.22,0),roof_material,frame=frame)
    chimney_bottom=ridge-w*.24*math.tan(theta)-1
    chimney_top=ridge+1.5
    block(m,'Chimney',(1.7,chimney_top-chimney_bottom,1.7),
          (w*.24,(chimney_top+chimney_bottom)/2,-d*.22),'M04',frame=frame,collide=True)
    block(m,'ChimneyCoping',(2.05,.45,2.05),(w*.24,chimney_top+.18,-d*.22),'M04',frame=frame)
    if canopy:
        depth=6.5
        for x in (-w*.4,w*.4):
            block(m,'CanopyPost',(.5,7.8,.5),(x,3.9,d/2+depth),'M02',frame=frame,collide=True)
        block(m,'CanopyFrontBeam',(w*.86,.45,.5),(0,7.9,d/2+depth),'M02',frame=frame)
        block(m,'LinenCanopy',(w*.86,.16,7.1),(0,8.6,d/2+3.2),'M08',rot=rx(.19),frame=frame)
        block(m,'CanopyValance',(w*.86,.65,.16),(0,7.9,d/2+6.65),'M08',frame=frame)
        block(m,'Counter',(10,.45,2.8),(2,2.7,d/2+4.6),'M03',frame=frame,collide=True)
        for x in (-2,6): block(m,'CounterLeg',(.45,2.5,.45),(x,1.25,d/2+4.6),'M02',frame=frame)
        for x in (-5,-2,5):
            block(m,'GoodsCrate',(2.1,1.6,1.9),(x,.8,d/2+2.4),'M03',frame=frame,collide=True)
    buildings.append({'name':name,'width':w,'depth':d,'floors':floors,'wallTop':wall_top,
                      'rise':rise,'roofMaterial':roof_material,'frame':frame})
    return m

def merchant(parent):
    m=model(parent,'Merchant_Reference','CharacterReference')
    f=((24,.4,16),ry(math.pi)) # face points toward +Z, toward the review camera
    root=block(m,'HumanoidRootPart',(2,2,1),(0,3,0),'M08',frame=f,shadow=False)
    prop(root,'float','Transparency',1)
    torso=block(m,'Torso',(1.8,2,1),(0,3,0),'M08',frame=f)
    head=block(m,'Head',(1.5,1.1,1.1),(0,4.65,0),'M08',frame=f,tint='#C8A481')
    mesh=item(head,'SpecialMesh','HeadShape')
    prop(mesh,'token','MeshType',0)
    prop(mesh,'Vector3','Scale',(1,1,1))
    face=item(head,'Decal','face')
    prop(face,'token','Face',5)
    prop(face,'Content','Texture','rbxasset://textures/face.png')
    for s in (-1,1):
        block(m,'Sleeve',(.8,1.1,1.0),(s*1.3,3.45,0),'M08',rot=rz(-s*.1),frame=f)
        block(m,'Hand',(.62,.9,.8),(s*1.35,2.5,-.02),'M08',frame=f,tint='#C8A481')
        block(m,'TrouserLeg',(.8,1.65,.9),(s*.47,1.18,0),'M06',frame=f)
        block(m,'Boot',(.86,.62,1.1),(s*.47,.38,-.1),'M07',frame=f)
    block(m,'LeatherApron',(1.62,2.1,.13),(0,2.7,-.57),'M07',frame=f)
    block(m,'Belt',(1.9,.19,1.08),(0,2.8,0),'M07',frame=f)
    block(m,'ApronStrap',(.19,1.5,.12),(-.4,3.6,-.59),'M07',frame=f)
    block(m,'Buckle',(.3,.23,.13),(0,2.8,-.65),'M09',frame=f,shadow=False)
    block(m,'MerchantCap',(1.6,.53,1.15),(0,5.24,.04),'M06',frame=f,shape=0)
    block(m,'CapBand',(1.55,.17,1.04),(0,5.02,0),'M07',frame=f)
    return m

def tree(parent):
    m=model(parent,'Oak_Reference','VegetationReference')
    frame=((-53,0,5),IDENTITY)
    block(m,'OakTrunk',(16,2.6,2.8),(0,8,0),'M02',frame=frame,rot=rz(math.pi/2-.06),shape=2,collide=True)
    # Cylinder parts have their axis along local X, so use block branches here.
    for x,y,z,angle in ((-3,15,0,.55),(3.2,14,1,-.65),(.5,17,-2.6,-.2)):
        block(m,'OakBranch',(1.2,8,1.2),(x,y,z),'M02',frame=frame,rot=rz(angle))
    for x,y,z,sx,sy,sz in ((0,22,0,16,11,14),(-7,19,1,12,9,12),(7,19,0,12,9,12),
                          (-2,20,6,13,9,11),(1,22,-6,13,10,11),(-5,25,-1,11,8,10),
                          (6,24,2,11,8,11)):
        block(m,'OakFoliage',(sx,sy,sz),(x,y,z),'M12',frame=frame,shape=0,shadow=False)
    return m

def write_xml(path, root):
    ET.indent(root,space='  ')
    ET.ElementTree(root).write(path,encoding='utf-8',xml_declaration=True)

def build():
    OUT.mkdir(exist_ok=True)
    xml=ET.Element('roblox',version='4')
    ET.SubElement(xml,'External').text='null'
    ET.SubElement(xml,'External').text='nil'
    ws=item(xml,'Workspace','Workspace')
    prop(ws,'bool','StreamingEnabled',True)
    prop(ws,'int','StreamingMinRadius',64)
    prop(ws,'int','StreamingTargetRadius',128)
    pilot=model(ws,'Crownlands_StylePilot_v01','StylePilot')
    attrs(pilot,ArtDirectionVersion='0.1',Style='A',Approval='Approved 2026-10-29',
          Stage='GeometryAndBuiltinMaterialPilot',ProductionTextures='Pending',
          LOD='Pending pilot acceptance')
    ground=model(pilot,'GroundAndRoad','EnvironmentReference')
    block(ground,'Meadow',(153,1.4,103),(0,-.7,0),'M11',collide=True)
    for x,z,sx,sz,angle in ((-34,24,52,7,8),(11,25,47,7,-5),(47,21,31,7,-11)):
        block(ground,'DirtRoad',(sx,.12,sz),(x,.06,z),'M10',rot=ry(math.radians(angle)),collide=True,shadow=False)
    house(pilot,'Cottage',(-29,0,-1),21,17,1,'M06',yaw=8)
    house(pilot,'Townhouse',(3,0,-15),24,20,2,'M05')
    house(pilot,'Workshop',(37,0,-2),26,18,1,'M05',yaw=-8,canopy=True)
    merchant(pilot)
    tree(pilot)
    fence=model(pilot,'BoundaryFence','PropReference')
    for x in range(-65,71,15):
        block(fence,'FencePost',(.65,4,.65),(x,2,-34),'M02',collide=True)
    for x in range(-65,56,15):
        for y in (1.3,3): block(fence,'FenceRail',(15,.4,.45),(x+7.5,y,-34),'M03',collide=True)
    spawn=part(pilot,'ReviewSpawn',(6,.1,6),(1,.08,35),'M10',cls='SpawnLocation',collide=True,shadow=False)
    prop(spawn,'bool','Neutral',True)
    prop(spawn,'int','Duration',0)
    prop(spawn,'float','Transparency',1)
    camera=item(ws,'Camera','Camera')
    eye=(90,57,113)
    focus=(0,10,-1)
    back=tuple(a-b for a,b in zip(eye,focus))
    norm=lambda v:tuple(x/math.sqrt(sum(y*y for y in v)) for x in v)
    back=norm(back)
    right=norm((back[2],0,-back[0]))
    up=(back[1]*right[2]-back[2]*right[1],back[2]*right[0]-back[0]*right[2],back[0]*right[1]-back[1]*right[0])
    rotation=tuple(v for row in zip(right,up,back) for v in row)
    prop(camera,'CoordinateFrame','CFrame',(eye,rotation))
    prop(camera,'CoordinateFrame','Focus',(focus,IDENTITY))
    prop(camera,'float','FieldOfView',50)
    prop(camera,'token','CameraType',0)
    prop(ws,'Ref','CurrentCamera',camera.get('referent'))
    light=item(xml,'Lighting','Lighting')
    prop(light,'float','Brightness',2.5)
    prop(light,'float','ClockTime',14)
    prop(light,'string','TimeOfDay','14:00:00')
    prop(light,'float','GeographicLatitude',40)
    prop(light,'bool','GlobalShadows',True)
    prop(light,'Color3','Ambient',(.43,.43,.39))
    prop(light,'Color3','OutdoorAmbient',(.51,.53,.48))
    prop(light,'float','EnvironmentDiffuseScale',1)
    prop(light,'float','EnvironmentSpecularScale',.3)
    prop(light,'float','ShadowSoftness',.35)
    prop(light,'float','FogEnd',2000)
    material_service=item(xml,'MaterialService','MaterialService')
    prop(material_service,'bool','Use2022Materials',True)
    # Export only the pilot hierarchy; do not drag Lighting changes into a map.
    mx=ET.Element('roblox',version='4')
    mx.append(deepcopy(pilot))
    write_xml(OUT/'Crownlands-StylePilot-v01.rbxlx',xml)
    write_xml(OUT/'Crownlands-StylePilot-v01.rbxmx',mx)
    counts=Counter(r['role'] for r in records)
    manifest={
        'version':'0.1','approval':'Art direction approved; pilot itself awaits visual review',
        'partCount':len(records),'partsByModel':dict(counts),
        'materials':sorted({r['material'] for r in records}),
        'runtimeScripts':0,'externalAssetIds':[],
        'textureStage':'Built-in Roblox materials tinted with the approved palette; not the custom M01-M12 maps',
        'buildings':buildings,'parts':records,
    }
    for f in sorted(OUT.glob('*.rbx*')):
        manifest[f.suffix[1:]+'Sha256']=hashlib.sha256(f.read_bytes()).hexdigest()
    (OUT/'manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    assert len(buildings)==3 and len(records)<450
    print(json.dumps({k:v for k,v in manifest.items() if k not in ('parts','buildings')},ensure_ascii=False,indent=2))

if __name__=='__main__': build()
