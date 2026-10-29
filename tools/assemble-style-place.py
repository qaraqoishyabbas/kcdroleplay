"""Decode the local Studio buffer, assemble a copy and preserve Terrain data.

Requires Lune and Python packages lz4 + zstandard. The current Lune cannot parse
the engine's empty Content value for Terrain.VoxelGridAssetContentMap. Preserve
that exact property chunk explicitly, with its class index remapped. Any other
unsupported Content value fails closed. Never promotes the result to the game.
"""
from pathlib import Path
import argparse
import base64
import hashlib
import json
import struct
import subprocess
import sys

ROOT=Path(__file__).resolve().parents[1]
p=argparse.ArgumentParser()
p.add_argument('--source',type=Path,required=True)
p.add_argument('--log',type=Path,required=True)
p.add_argument('--output',type=Path,required=True)
p.add_argument('--lune',type=Path,required=True)
p.add_argument('--python-deps',type=Path)
a=p.parse_args()
if a.python_deps: sys.path.insert(0,str(a.python_deps))
import lz4.block
import zstandard

def chunks(blob):
    assert blob[:8]==b'<roblox!'
    offset=32
    while offset<len(blob):
        tag,compressed,raw,reserved=struct.unpack_from('<4sIII',blob,offset)
        end=offset+16+(compressed or raw)
        packed=blob[offset+16:end]
        data=packed
        if compressed:
            data=(zstandard.ZstdDecompressor().decompress(packed) if packed[:4]==bytes.fromhex('28b52ffd')
                  else lz4.block.decompress(packed,uncompressed_size=raw))
        assert len(data)==raw
        yield tag,data,blob[offset:end]
        offset=end

def classes(blob):
    result={}
    for tag,data,_ in chunks(blob):
        if tag==b'INST':
            idx,n=struct.unpack_from('<II',data)
            result[idx]=data[8:8+n].decode()
    return result

def properties(blob):
    names=classes(blob)
    for tag,data,_ in chunks(blob):
        if tag==b'PROP':
            idx,n=struct.unpack_from('<II',data)
            yield names[idx],data[8:8+n].decode(),data[8+n:],data

def shared_strings(blob):
    values=[]
    for tag,data,_ in chunks(blob):
        if tag!=b'SSTR': continue
        version,count=struct.unpack_from('<II',data)
        assert version==0
        off=8
        for _ in range(count):
            off+=16
            n=struct.unpack_from('<I',data,off)[0]; off+=4
            values.append(data[off:off+n]); off+=n
        assert off==len(data)
    return values

def semantic(body,strings):
    if body[0]==0x1C:
        assert len(body)==5
        return strings[struct.unpack('>I',body[1:])[0]]
    if body[0]==1:
        n=struct.unpack_from('<I',body,1)[0]
        assert len(body)==5+n
        return body[5:]
    return body

text=a.log.read_text(encoding='utf-8')
assert '\nSAVE_DONE\n' in text or '\nSAVE_DONE\r\n' in text,'Native serialization did not complete'
reports=[json.loads(line.split(' ',1)[1]) for line in text.splitlines() if line.startswith('STYLE_MAIN_JSON ')]
assert len(reports)==1 and reports[0]['buildings']==103 and not reports[0]['unionFailures']
assert reports[0]['afterParts']<reports[0]['beforeParts']
size=[int(line.split()[1]) for line in text.splitlines() if line.startswith('SAVE_SIZE ')]
parts=[line.split(' ',2) for line in text.splitlines() if line.startswith('SAVE_CHUNK ')]
assert [int(line[1]) for line in parts]==list(range(1,len(parts)+1))
encoded=''.join(line[2] for line in parts)
assert size==[len(encoded)]
native=base64.b64decode(encoded,validate=True)
assert native[:8]==b'<roblox!'
a.output.parent.mkdir(parents=True,exist_ok=True)
native_path=a.output.with_suffix('.native.rbxm')
native_path.write_bytes(native)
xml_path=a.output.with_suffix('.rbxlx')
run=subprocess.run([str(a.lune),'run',str(ROOT/'tools/assemble-style-place.luau'),
    str(a.source),str(native_path),str(a.output),str(xml_path),str(ROOT)],capture_output=True,text=True,encoding='utf-8')
(a.output.parent/'file-assembly.log').write_text(run.stdout+run.stderr,encoding='utf-8')
assert run.returncode==0,run.stdout+run.stderr
print(run.stdout.strip())
original=a.source.read_bytes()
result=a.output.read_bytes()
source_properties={(cls,name):(body,data) for cls,name,body,data in properties(original)}
result_properties={(cls,name):(body,data) for cls,name,body,data in properties(result)}
preserved=[]
append=[]
new_classes={v:k for k,v in classes(result).items()}
result_class_names=classes(result)
source_strings=shared_strings(original)
result_strings=shared_strings(result)
materials_index=struct.unpack('>I',result_properties[('Terrain','Materials')][0][1:])[0]
terrain_materials=bytearray(result_strings[materials_index])
assert struct.unpack_from('<II',terrain_materials)==(1,21) and len(terrain_materials)==323
changed_materials=set()
for i in range(21):
    pos=8+i*15
    material_id=struct.unpack_from('<I',terrain_materials,pos+7)[0]
    if material_id in (1280,1360):
        expected=bytes((100,118,64)) if material_id==1280 else bytes((121,104,75))
        replacement=bytes((116,128,90)) if material_id==1280 else bytes((137,116,84))
        assert terrain_materials[pos+4:pos+7]==expected
        terrain_materials[pos+4:pos+7]=replacement
        changed_materials.add(material_id)
assert changed_materials=={1280,1360}
for (cls,name),(body,data) in source_properties.items():
    if body[0]==0x23:
        assert cls=='Terrain' and name=='VoxelGridAssetContentMap' and body==bytes.fromhex('23020000000000000000'),(
            'Unrecognized nonempty Content data',cls,name,len(body))
        assert (cls,name) not in result_properties
        fixed=struct.pack('<I',new_classes[cls])+data[4:]
        append.append(struct.pack('<4sIII',b'PROP',0,len(fixed),0)+fixed)
        preserved.append(cls+'.'+name)
for cls,name,body,_ in properties(native):
    assert body[0]!=0x23,('Native buffer has unsupported Content data',cls,name)
for (cls,name),(body,_) in source_properties.items():
    if cls=='Terrain' and name not in ('VoxelGridAssetContentMap','MaterialColors','CustomPhysicalProperties'):
        assert (cls,name) in result_properties and semantic(result_properties[(cls,name)][0],result_strings)==semantic(body,source_strings),('Terrain changed',name)
assert source_properties[('Terrain','CustomPhysicalProperties')][0]==bytes.fromhex('1902')
# MaterialColors consists of six reserved bytes and 21 RGB triplets. Preserve
# the layout and replace only the two colors already customized by build-map.
key=('Terrain','MaterialColors')
before=source_properties[key][0]
assert before[0]==1 and struct.unpack_from('<I',before,1)[0]==69
palette=bytearray(before[5:])
for old,new in [(bytes((100,118,64)),bytes((116,128,90))),
                (bytes((121,104,75)),bytes((137,116,84)))]:
    matches=[i for i in range(6,len(palette)-2,3) if palette[i:i+3]==old]
    assert len(matches)==1,('Ambiguous terrain palette entry',old,matches)
    palette[matches[0]:matches[0]+3]=new
new_palette=before[:5]+bytes(palette)
out=result[:32]
compressor=zstandard.ZstdCompressor(level=3)
for tag,data,packed in chunks(result):
    if tag==b'SSTR':
        version,total=struct.unpack_from('<II',data)
        rebuilt=data[:8]; offset=8
        for index in range(total):
            digest=data[offset:offset+16]; offset+=16
            n=struct.unpack_from('<I',data,offset)[0]; offset+=4
            content=data[offset:offset+n]; offset+=n
            if index==materials_index:
                content=bytes(terrain_materials)
                digest=hashlib.md5(content).digest()
            rebuilt+=digest+struct.pack('<I',len(content))+content
        assert offset==len(data)
        data=rebuilt
    if tag==b'PROP':
        idx,n=struct.unpack_from('<II',data)
        if result_class_names[idx]=='Terrain' and data[8:8+n].decode()=='MaterialColors':
            data=data[:8+n]+new_palette
        if result_class_names[idx]=='Terrain' and data[8:8+n].decode()=='CustomPhysicalProperties':
            data=data[:8+n]+source_properties[('Terrain','CustomPhysicalProperties')][0]
    compressed=compressor.compress(data)
    packed=(struct.pack('<4sIII',tag,len(compressed),len(data),0)+compressed
            if len(compressed)<len(data) and tag!=b'END\x00'
            else struct.pack('<4sIII',tag,0,len(data),0)+data)
    if tag==b'END\x00': out+=b''.join(append)
    out+=packed
a.output.write_bytes(out)
reports[0]['outputSha256']=hashlib.sha256(out).hexdigest()
reports[0]['sourceSha256']=hashlib.sha256(original).hexdigest()
reports[0]['preservedEngineProperties']=preserved
reports[0]['terrainGeometryPreserved']=True
reports[0]['streamingMinRadius']=128
reports[0]['streamingTargetRadius']=512
reports[0]['nativeBufferBytes']=len(native)
reports[0]['outputBytes']=len(out)
(a.output.parent/'migration-result.json').write_text(json.dumps(reports[0],indent=2,ensure_ascii=False)+'\n',encoding='utf-8')
print(json.dumps({k:v for k,v in reports[0].items() if k not in ('variants','unionFailures')},indent=2))
