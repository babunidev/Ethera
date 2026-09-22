"""Old low-poly stand-in builder. Do not run; it would overwrite the current sculpt.

The runtime character is the Mixamo-rigged model prepared by
`art/process_khar_morr_glb.py`.
"""
raise SystemExit("Use art/process_khar_morr_glb.py; this script built the first low-poly stand-in.")
import bpy, math, random, json
from pathlib import Path
from mathutils import Vector

ROOT = Path(r'C:\Users\Babun\Documents\Morkahja\Ethera-The-Stonewrought')
OUT = ROOT / 'art'
random.seed(27)
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)
for block in list(bpy.data.collections):
    if block.name != 'Collection': bpy.data.collections.remove(block)
asset = bpy.data.collections.get('Collection')
asset.name = 'KHAR-MORR | game asset'
S = 1.7 / 7.25
parts = []

def mat(name, rgb, rough=0.85, emit=0):
    m=bpy.data.materials.new(name); m.diffuse_color=(*rgb,1); m.use_nodes=True
    p=m.node_tree.nodes.get('Principled BSDF')
    p.inputs['Base Color'].default_value=(*rgb,1)
    p.inputs['Roughness'].default_value=rough
    if emit:
        p.inputs['Emission Color'].default_value=(*rgb,1)
        p.inputs['Emission Strength'].default_value=emit
    return m

stone=[mat('Limestone / '+n,c) for n,c in [
    ('warm body',(0.48,0.43,0.34)),('lit facets',(0.57,0.52,0.43)),
    ('ochre facets',(0.43,0.37,0.28)),('pale facets',(0.63,0.58,0.49))]]
face_mat=mat('Carved face / pale limestone',(0.66,0.60,0.49))
dark=mat('Deep mineral seams',(0.105,0.115,0.105))
crystal=mat('Quartz / cloudy blue',(0.40,0.67,0.70),.24)
crystal_light=mat('Quartz / pale planes',(0.68,0.83,0.81),.28)
eye=mat('Eyes / turquoise resonance',(0.12,0.82,0.86),.22,2.2)

def bind(o, bone, materials=None, vary=True):
    if materials is None: materials=stone
    for m in materials: o.data.materials.append(m)
    for p in o.data.polygons:
        p.use_smooth=False
        if vary and len(materials)>1:
            p.material_index=random.choices(range(len(materials)),[7]+[1]*(len(materials)-1))[0]
    group=o.vertex_groups.new(name=bone); group.add(list(range(len(o.data.vertices))),1.0,'REPLACE')
    parts.append(o)
    return o

def rock(name, loc, scale, bone, sub=1, materials=None, rough=.065):
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=sub,radius=1,location=loc)
    o=bpy.context.object; o.name=name
    for v in o.data.vertices:
        v.co *= 1+random.uniform(-rough,rough)
    o.scale=scale
    bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    return bind(o,bone,materials)

def segment(name,a,b,rx,ry,bone,sub=2):
    a,b=Vector(a),Vector(b)
    o=rock(name,(a+b)/2,(rx,ry,(b-a).length*.58),bone,sub)
    o.rotation_mode='QUATERNION';o.rotation_quaternion=Vector((0,0,1)).rotation_difference(b-a)
    return o

def mesh(name, verts, faces, bone, materials=None):
    m=bpy.data.meshes.new(name);m.from_pydata(verts,[],faces);m.update()
    o=bpy.data.objects.new(name,m);asset.objects.link(o);return bind(o,bone,materials)

def rings(name, rows, bone, n=10, materials=None):
    # Each row is (height, width, depth, y center); front is Blender -Y.
    verts=[]
    for z,w,d,y in rows:
        for i in range(n):
            t=2*math.pi*i/n
            verts.append((w*math.sin(t),y-d*math.cos(t),z))
    faces=[tuple(range(n-1,-1,-1))]
    for j in range(len(rows)-1):
        for i in range(n):
            a=j*n+i;b=j*n+(i+1)%n;c=b+n;d=a+n
            if (i+j)%2: faces += [(a,b,d),(b,c,d)]
            else: faces += [(a,b,c),(a,c,d)]
    faces.append(tuple(range((len(rows)-1)*n,len(rows)*n)))
    return mesh(name,verts,faces,bone,materials)

def shard(name,base,tip,width,bone):
    a,b=Vector(base),Vector(tip);axis=(b-a).normalized()
    u=axis.cross(Vector((0,1,0))).normalized();v=axis.cross(u)
    verts=[]
    for height,r in [(0,.72),(.64,1)]:
        for i in range(5):
            t=i*math.tau/5
            verts.append(a+(b-a)*height+(u*math.cos(t)+v*math.sin(t))*width*r)
    verts.append(b)
    faces=[(4,3,2,1,0)]
    for i in range(5):
        j=(i+1)%5;faces.extend([(i,j,j+5,i+5),(i+5,j+5,10)])
    return mesh(name,verts,faces,bone,[crystal,crystal_light])

# Core anatomy: joined broad forms, with smaller mineral plates following muscle lines.
rings('Pelvic stone',[(3.10,.35,.28,0),(3.40,.61,.39,0),(3.72,.73,.40,0),(3.92,.53,.30,0)],'pelvis')
rings('Torso foundation',[(3.72,.53,.31,0),(4.02,.52,.32,0),(4.42,.66,.34,0),(4.80,.83,.39,0),(5.22,.98,.40,0),(5.55,.86,.34,.01),(5.70,.43,.29,.02)],'chest',12)
rock('Neck',(0,0,5.90),(.29,.28,.46),'head',2)
for s in [-1,1]:
    side='L' if s>0 else 'R'
    segment('Clavicle '+side,(s*.18,-.19,5.52),(s*.91,-.05,5.49),.22,.25,'chest')
    rock('Chest plane '+side,(s*.40,-.34,5.06),(.44,.32,.34),'chest',2)
    segment('Oblique '+side,(s*.51,-.25,4.48),(s*.37,-.27,3.92),.20,.15,'chest')
    segment('Hip crest '+side,(s*.32,-.25,3.78),(s*.65,-.12,3.66),.20,.19,'pelvis')
    rock('Hip '+side,(s*.56,.07,3.45),(.46,.40,.47),'pelvis',2)
for z,w in [(4.63,.24),(4.30,.23),(4.03,.20)]:
    for s in [-1,1]: rock('Abdominal plate',(s*w*.65,-.322,z),(w,.15,.21),'chest',1)

bones={'root':((0,0,0),(0,0,.4),None),'pelvis':((0,0,3.45),(0,0,4.0),'root'),
       'chest':((0,0,4.0),(0,0,5.62),'pelvis'),'head':((0,0,5.62),(0,0,6.83),'chest')}

for s in [-1,1]:
    side='L' if s>0 else 'R'
    hip=(s*.52,0,3.50); knee=(s*.63,-.035,2.08); ankle=(s*.66,.01,.54)
    shoulder=(s*1.00,0,5.40);elbow=(s*1.39,-.025,4.45);wrist=(s*1.62,-.12,3.59)
    hand=(s*1.69,-.18,3.22)
    for name,head,tail,parent in [('thigh',hip,knee,'pelvis'),('shin',knee,ankle,'thigh.'+side),
        ('foot',ankle,(s*.66,-.64,.20),'shin.'+side),('upper_arm',shoulder,elbow,'chest'),
        ('forearm',elbow,wrist,'upper_arm.'+side),('hand',wrist,hand,'forearm.'+side)]:
        bones[name+'.'+side]=(head,tail,parent)
    segment('Thigh mass '+side,hip,knee,.46,.40,'thigh.'+side)
    segment('Quadriceps facet '+side,(s*.57,-.24,3.29),(s*.66,-.26,2.31),.31,.22,'thigh.'+side)
    rock('Knee seam '+side,knee,(.255,.245,.23),'shin.'+side,1,[dark])
    rock('Kneecap '+side,(s*.63,-.23,2.09),(.31,.23,.34),'shin.'+side,1)
    segment('Calf '+side,(s*.65,.08,1.98),(s*.66,.055,.72),.34,.33,'shin.'+side)
    segment('Shin ridge '+side,(s*.64,-.18,1.92),(s*.66,-.16,.68),.22,.21,'shin.'+side,1)
    rock('Ankle '+side,ankle,(.23,.25,.23),'foot.'+side,1)
    rock('Foot '+side,(s*.66,-.23,.24),(.31,.50,.24),'foot.'+side,2)
    for i in range(4):
        x=s*(.44+i*.135)
        rock('Toe '+side,(x,-.58+abs(i-1)*.018,.15),(.093,.19,.14),'foot.'+side,1)
    rock('Shoulder '+side,(s*1.02,0,5.39),(.49,.40,.41),'upper_arm.'+side,2)
    segment('Upper arm '+side,shoulder,elbow,.33,.31,'upper_arm.'+side)
    rock('Elbow seam '+side,elbow,(.20,.21,.20),'forearm.'+side,1,[dark])
    segment('Forearm '+side,(s*1.40,0,4.43),wrist,.28,.28,'forearm.'+side)
    segment('Forearm ridge '+side,(s*1.56,-.17,4.33),(s*1.68,-.22,3.72),.20,.19,'forearm.'+side,1)
    rock('Wrist '+side,wrist,(.19,.17,.19),'hand.'+side,1)
    segment('Palm '+side,wrist,hand,.23,.15,'hand.'+side,1)
    for i in range(4):
        x=s*(1.54+i*.105); top=(x,-.18,3.25);mid=(x+s*.045,-.17,3.04);tip=(x+s*.015,-.235,2.86+abs(i-1)*.045)
        segment('Finger proximal '+side,top,mid,.062,.073,'hand.'+side,1)
        segment('Finger distal '+side,mid,tip,.056,.063,'hand.'+side,1)
    segment('Thumb '+side,(s*1.51,-.19,3.40),(s*1.40,-.24,3.17),.08,.09,'hand.'+side,1)
    shard('Shoulder quartz '+side,(s*1.13,.02,5.63),(s*1.18,.01,6.00),.105,'upper_arm.'+side)
    shard('Shoulder quartz small '+side,(s*1.30,.03,5.57),(s*1.43,.03,5.82),.065,'upper_arm.'+side)
    for i in range(3):
        shard('Forearm quartz '+side,(s*(1.51+.07*i),.02,4.32-.20*i),
              (s*(1.70+.06*i),.01,4.59-.22*i),.067,'forearm.'+side)
    shard('Hip quartz '+side,(s*.86,-.08,3.21),(s*.91,-.13,3.56),.068,'thigh.'+side)
    for z in [1.63,1.16,.73]:
        shard('Calf quartz '+side,(s*.91,.0,z),(s*1.02,-.02,z+.22),.058,'shin.'+side)

# Carved face: a deliberately planar face, with cheek/jaw contours and separate eyes.
rings('Face carved planes',[(5.98,.16,.17,-.20),(6.07,.28,.24,-.15),(6.24,.34,.31,-.12),
    (6.46,.39,.34,-.095),(6.67,.38,.28,-.04),(6.88,.27,.24,0)],'head',12,[face_mat])
rock('Cranium',(0,.07,6.58),(.40,.36,.52),'head',2)
for s in [-1,1]:
    rock('Cheek plane',(s*.245,-.354,6.35),(.145,.10,.13),'head',1,[face_mat])
    # Angular deep eye sockets surrounding narrow luminous eyes.
    rock('Eye socket',(s*.175,-.382,6.53),(.158,.056,.080),'head',1,[dark])
    rock('Luminous eye',(s*.175,-.435,6.53),(.083,.025,.030),'head',2,[eye],0)
    segment('Stone brow',(s*.04,-.40,6.64),(s*.32,-.33,6.64),.077,.075,'head',1)
    rock('Jaw facet',(s*.21,-.27,6.14),(.15,.13,.15),'head',1,[face_mat])
mesh('Nose',[(0,-.41,6.58),(-.071,-.42,6.35),(.071,-.42,6.35),
    (0,-.55,6.33),(-.078,-.42,6.31),(.078,-.42,6.31)],
    [(0,1,3),(0,3,2),(1,4,3),(2,3,5),(3,4,5)],'head',[face_mat])
mesh('Mouth seam',[(-.13,-.393,6.21),(0,-.42,6.225),(.13,-.393,6.21),(0,-.418,6.192)],[(0,1,2,3)],'head',[dark])
rock('Chin',(0,-.30,6.09),(.18,.13,.10),'head',1,[face_mat])
# The mineral mane follows the silhouette of the concept, not human strands.
for s in [-1,1]:
    for i,(x,y,z,rx,ry,rz) in enumerate([
        (.19,.03,6.99,.27,.29,.24),(.40,.04,6.87,.30,.32,.26),
        (.48,.02,6.65,.28,.33,.24),(.55,.035,6.43,.28,.34,.23),
        (.51,.12,6.20,.28,.34,.22),(.55,.18,5.98,.27,.34,.24),
        (.53,.20,5.75,.24,.30,.23),(.43,.22,5.55,.23,.27,.23)]):
        o=rock('Layered mineral mane',(s*x,y,z),(rx,ry,rz),'head',1)
        o.rotation_euler.y=s*.20
    for z in [6.85,6.50,6.17,5.87]:
        rock('Rear mane',(s*.25,.34,z),(.29,.25,.29),'head',1)
shard('Forehead quartz',(0,-.31,6.74),(0,-.35,7.05),.105,'head')
rock('Crown keystone',(0,.035,7.06),(.17,.22,.18),'head',1)

# Join into a single skinned mesh. Discrete stone plates use rigid weighting intentionally.
bpy.ops.object.select_all(action='DESELECT')
for o in parts:o.select_set(True)
bpy.context.view_layer.objects.active=parts[0]
bpy.ops.object.join();body=bpy.context.object;body.name='KharMorr_StoneBody'
bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
for v in body.data.vertices:v.co*=S
arm_data=bpy.data.armatures.new('KharMorr_Rig');rig=bpy.data.objects.new('KharMorr_Rig',arm_data);asset.objects.link(rig)
bpy.context.view_layer.objects.active=rig;rig.select_set(True);body.select_set(False)
bpy.ops.object.mode_set(mode='EDIT')
for name,(head,tail,parent) in bones.items():
    b=arm_data.edit_bones.new(name);b.head=Vector(head)*S;b.tail=Vector(tail)*S
    if parent:b.parent=arm_data.edit_bones[parent]
bpy.ops.object.mode_set(mode='OBJECT')
rig.show_in_front=True;rig.display_type='WIRE'
body.parent=rig;mod=body.modifiers.new('Living stone articulation','ARMATURE');mod.object=rig
back=bpy.data.objects.new('back',None);asset.objects.link(back);back.parent=rig
# Bone parenting retains a real animated attachment for the club.
back.parent_type='BONE';back.parent_bone='chest'
back.location=(0,-.18,0) # Reset below by placing in world space after dependency evaluation.
bpy.context.view_layer.update()
back.matrix_world.translation=Vector((0,.94,4.90))*S
back.empty_display_size=.06

# Explicit in-place looping actions, at 30 fps. No root motion enters gameplay.
scene=bpy.context.scene;scene.render.fps=30
for name,end in [('Idle',60),('Walk',30)]:
    rig.animation_data_create();rig.animation_data.action=bpy.data.actions.new(name)
    for f in range(1,end+2):
        t=(f-1)/end*math.tau
        for pb in rig.pose.bones:
            pb.rotation_mode='XYZ';pb.rotation_euler=(0,0,0);pb.location=(0,0,0)
        if name=='Idle':
            rig.pose.bones['chest'].rotation_euler.x=.012*math.sin(t)
            rig.pose.bones['head'].rotation_euler.z=.018*math.sin(t)
        else:
            rig.pose.bones['pelvis'].location.y=.065*S*(1-math.cos(2*t))
            rig.pose.bones['pelvis'].rotation_euler.z=.025*math.sin(t)
            rig.pose.bones['chest'].rotation_euler.y=.035*math.sin(t)
            for side,phase in [('L',t),('R',t+math.pi)]:
                swing=math.sin(phase)
                rig.pose.bones['thigh.'+side].rotation_euler.x=.40*swing
                rig.pose.bones['shin.'+side].rotation_euler.x=-.46*max(0,-swing)
                rig.pose.bones['foot.'+side].rotation_euler.x=-.12*swing
                rig.pose.bones['upper_arm.'+side].rotation_euler.x=-.24*swing
                rig.pose.bones['forearm.'+side].rotation_euler.x=-.07-.06*max(0,swing)
        for pb in rig.pose.bones:
            pb.keyframe_insert(data_path='rotation_euler',frame=f,group=pb.name)
            if pb.name=='pelvis':pb.keyframe_insert(data_path='location',frame=f,group=pb.name)
    action=rig.animation_data.action
    track=rig.animation_data.nla_tracks.new();track.name=name
    strip=track.strips.new(name,1,action);track.mute=True
rig.animation_data.action=None
for pb in rig.pose.bones:pb.rotation_euler=(0,0,0);pb.location=(0,0,0)
scene.frame_set(1);scene.frame_start=1;scene.frame_end=60
bpy.ops.object.select_all(action='DESELECT')
for o in [rig,body,back]:o.select_set(True)
bpy.context.view_layer.objects.active=rig
OUT.mkdir(exist_ok=True)
bpy.ops.export_scene.gltf(filepath=str(ROOT/'assets/models/khar_morr.glb'),use_selection=True,
    export_format='GLB',export_animations=True,export_animation_mode='NLA_TRACKS',
    export_force_sampling=True,export_anim_slide_to_zero=True,export_yup=True)

# Separate render collection, excluded from the exported asset.
studio=bpy.data.collections.new('STUDIO | preview only');scene.collection.children.link(studio)
def to_studio(o):
    for c in list(o.users_collection):c.objects.unlink(o)
    studio.objects.link(o)
def aim(o,p):o.rotation_euler=(Vector(p)-o.location).to_track_quat('-Z','Y').to_euler()
bpy.ops.mesh.primitive_plane_add(size=200,location=(0,0,-.008));ground=bpy.context.object;ground.name='Studio floor';to_studio(ground)
ground.data.materials.append(mat('Studio charcoal',(0.045,.055,.067),1))
for name,loc,power,size,color in [('Key',(-3,-4,5),500,4,(1,.87,.70)),('Fill',(3,-1,3),260,3,(.67,.82,1)),('Rim',(1,3,4),650,3,(.70,.85,1))]:
    data=bpy.data.lights.new(name,'AREA');data.energy=power;data.shape='DISK';data.size=size;data.color=color
    o=bpy.data.objects.new(name,data);studio.objects.link(o);o.location=loc;aim(o,(0,0,.8))
data=bpy.data.cameras.new('Portrait');cam=bpy.data.objects.new('Portrait',data);studio.objects.link(cam)
cam.location=(2.5,-5.2,2.35);aim(cam,(0,0,.86));data.type='ORTHO';data.ortho_scale=2.15;scene.camera=cam
scene.render.engine='CYCLES';scene.cycles.samples=32
scene.render.resolution_x=1100;scene.render.resolution_y=1200;scene.render.resolution_percentage=100
scene.world.color=(.18,.18,.18)
scene.view_settings.view_transform='AgX'
scene.render.image_settings.file_format='PNG';scene.render.filepath=str(OUT/'khar_morr_preview.png')
# Save with the game asset selected and the studio hidden in the modeling viewport.
studio.hide_viewport=True
bpy.ops.object.select_all(action='DESELECT');body.select_set(True);bpy.context.view_layer.objects.active=body
for screen in bpy.data.screens:
    for area in screen.areas:
        if area.type=='VIEW_3D':
            area.spaces.active.region_3d.view_distance=2.8
            area.spaces.active.region_3d.view_location=(0,0,.86)
            area.spaces.active.clip_end=100
            area.spaces.active.shading.type='MATERIAL'
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'khar_morr.blend'))
studio.hide_viewport=False
bpy.ops.render.render(write_still=True)
report={'vertices':len(body.data.vertices),'triangles':sum(len(p.vertices)-2 for p in body.data.polygons),
        'bones':len(bones),'height_m':round(max(v.co.z for v in body.data.vertices)-min(v.co.z for v in body.data.vertices),3),
        'front':'Blender -Y exports to Godot +Z; simulation yaw atan2(x,z)',
        'animations':['Idle','Walk'],'source':'FEMALE/Khar-Morr the First Carved.png; archived bare low-poly reference'}
(OUT/'khar_morr_build.json').write_text(json.dumps(report,indent=2))
print('KHAR_MORR_BUILD',json.dumps(report))
