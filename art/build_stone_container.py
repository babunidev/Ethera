"""Smooth grown-stone basin. Blender --background --python this_file -- OUTPUT_DIR.

Without OUTPUT_DIR, save the editable source in art/ and GLB in assets/models/.
LidPivot slides 0.16 m along local X and returns over two seconds in Godot.
"""
import bpy, math, sys
from pathlib import Path
from mathutils import Vector

root=Path(__file__).resolve().parents[1]
staged=Path(sys.argv[sys.argv.index('--')+1]) if '--' in sys.argv else None
art=staged or root/'art'
models=staged or root/'assets/models'
art.mkdir(parents=True,exist_ok=True);models.mkdir(parents=True,exist_ok=True)
bpy.ops.wm.read_factory_settings(use_empty=True)

def material(name,color,roughness,metallic=0):
 m=bpy.data.materials.new(name);m.diffuse_color=(*color,1);m.use_nodes=True
 p=m.node_tree.nodes.get('Principled BSDF')
 p.inputs['Base Color'].default_value=(*color,1)
 p.inputs['Roughness'].default_value=roughness
 p.inputs['Metallic'].default_value=metallic
 return m

stone=material('Warm flowing stone',(.32,.285,.23),.76)
crystal=material('Deep jade crystals',(.055,.26,.22),.23,.12)
gem=material('Clasp jade',(.08,.38,.32),.18,.18)

def profile_mesh(name,profile,mat,roots=False):
 # Catmull-Rom profile, revolved elliptically: continuous outer wall, rounded rim,
 # inner bowl and floor are one closed mesh rather than overlapping shells.
 samples=[]
 for i in range(len(profile)-1):
  a,b,c,d=profile[max(0,i-1)],profile[i],profile[i+1],profile[min(len(profile)-1,i+2)]
  for j in range(8):
   t=j/8
   samples.append([.5*((2*b[k])+(-a[k]+c[k])*t+(2*a[k]-5*b[k]+4*c[k]-d[k])*t*t+(-a[k]+3*b[k]-3*c[k]+d[k])*t*t*t) for k in range(3)])
 samples.append(profile[-1])
 verts=[];faces=[];n=96
 for rx,ry,z in samples:
  for j in range(n):
   angle=j*2*math.pi/n
   lobes=(.10*math.cos(5*angle+.4)+.055*math.sin(3*angle))*math.exp(-max(z,0)*11) if roots else 0
   verts.append((max(.0001,rx)*(1+lobes)*math.cos(angle),max(.0001,ry)*(1+lobes)*math.sin(angle),z))
 for i in range(len(samples)-1):
  for j in range(n):
   a=i*n+j;b=i*n+(j+1)%n
   faces.append((a,b,b+n,a+n))
 faces.append(tuple(reversed(range(n))))
 faces.append(tuple((len(samples)-1)*n+j for j in range(n)))
 mesh=bpy.data.meshes.new(name);mesh.from_pydata(verts,[],faces);mesh.update()
 obj=bpy.data.objects.new(name,mesh);bpy.context.collection.objects.link(obj)
 obj.data.materials.append(mat)
 for p in mesh.polygons:p.use_smooth=True
 return obj

basin=profile_mesh('GrownStoneBasin',[
 (.005,.004,-.035),(.29,.22,-.035),(.395,.27,-.02),(.36,.245,.015),
 (.285,.205,.07),(.23,.165,.16),(.235,.17,.24),(.30,.205,.30),
 (.385,.25,.36),(.415,.27,.43),(.422,.277,.485),(.405,.267,.512),
 (.377,.237,.512),(.354,.216,.485),(.341,.208,.43),(.30,.183,.365),
 (.22,.13,.323),(.10,.06,.312),(.002,.001,.312)],stone,True)

pivot=bpy.data.objects.new('LidPivot',None);bpy.context.collection.objects.link(pivot)
pivot.location=(0,.235,.516)
lid=profile_mesh('ThickStoneLid',[
 (.002,.001,.514),(.28,.17,.514),(.385,.245,.514),(.419,.273,.528),
 (.43,.281,.550),(.417,.270,.582),(.37,.232,.601),(.23,.135,.610),(.002,.001,.613)],stone)
lid.parent=pivot;lid.location=-pivot.location

def pebble(name,loc,scale,mat,parent=None):
 bpy.ops.mesh.primitive_uv_sphere_add(segments=32,ring_count=20,location=loc)
 o=bpy.context.object;o.name=name;o.scale=scale;o.data.materials.append(mat)
 bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
 for p in o.data.polygons:p.use_smooth=True
 if parent:
  o.parent=parent;o.location-=parent.location
 return o

# The clasp is shaped stone with an inset polished cabochon, not a metal padlock.
pebble('RoundedStoneClasp',(0,-.269,.519),(.072,.029,.076),stone,pivot)
pebble('CentralClaspGem',(0,-.292,.522),(.039,.015,.045),gem,pivot)

def crystal_spire(name,loc,radius,height,tilt):
 verts=[];faces=[];n=8
 for rad,z in [(radius*.65,0),(radius,.025),(radius*.86,height*.64),(.002,height)]:
  for j in range(n):
   angle=j*2*math.pi/n;verts.append((rad*math.cos(angle),rad*math.sin(angle),z))
 for ring in range(3):
  for j in range(n):faces.append((ring*n+j,ring*n+(j+1)%n,(ring+1)*n+(j+1)%n,(ring+1)*n+j))
 faces.extend([tuple(reversed(range(n))),tuple(24+j for j in range(n))])
 mesh=bpy.data.meshes.new(name);mesh.from_pydata(verts,[],faces);mesh.update()
 o=bpy.data.objects.new(name,mesh);bpy.context.collection.objects.link(o)
 o.location=loc;o.rotation_euler=tilt;o.data.materials.append(crystal)
 bevel=o.modifiers.new('Soft mineral edges','BEVEL');bevel.width=.005;bevel.segments=3
 for p in mesh.polygons:p.use_smooth=True
 # Crystals sit on the lid ends and travel with the stone slice.
 o.parent=pivot;o.location-=pivot.location
 return o

for sign in (-1,1):
 for k,(x,y,r,h) in enumerate([(.335,0,.028,.105),(.30,.042,.018,.067),(.355,-.035,.017,.057)]):
  crystal_spire(('Left' if sign<0 else 'Right')+'EndCrystal'+str(k),(sign*x,y,.584),r,h,(0,sign*.22,0))

bpy.ops.object.select_all(action='SELECT')
sys.path.insert(0,str(Path(__file__).parent))
from stone_surface import apply_stone_texture
apply_stone_texture(stone,art)
bpy.ops.wm.save_as_mainfile(filepath=str(art/'stone_container.blend'))
bpy.ops.export_scene.gltf(filepath=str(models/'stone_container.glb'),export_format='GLB',use_selection=True)

# Preview scene only; cameras and ground are not exported or saved into the asset.
scene=bpy.context.scene;scene.render.engine='CYCLES';scene.cycles.samples=32
scene.render.resolution_x=960;scene.render.resolution_y=760;scene.render.resolution_percentage=100
scene.world=bpy.data.worlds.new('Studio');scene.world.use_nodes=True
scene.world.node_tree.nodes['Background'].inputs[0].default_value=(.20,.23,.27,1)
scene.world.node_tree.nodes['Background'].inputs[1].default_value=.45
bpy.ops.mesh.primitive_plane_add(size=200)
bpy.context.object.data.materials.append(material('PreviewEarth',(.12,.10,.075),1))
for loc,power,size in [((1,-2,3),200,2),((-2,0,2),110,2),((0,2,2),130,1.5)]:
 bpy.ops.object.light_add(type='AREA',location=loc);o=bpy.context.object;o.data.energy=power;o.data.shape='DISK';o.data.size=size
 o.rotation_euler=(Vector((0,0,.35))-o.location).to_track_quat('-Z','Y').to_euler()
bpy.ops.object.camera_add(location=(1,-1.7,1.3))
camera=bpy.context.object;camera.rotation_euler=(Vector((0,0,.4))-camera.location).to_track_quat('-Z','Y').to_euler()
camera.data.type='ORTHO';camera.data.ortho_scale=1.35;scene.camera=camera
for state,angle in [('closed',0),('open',.16)]:
 pivot.location.x=angle
 scene.render.filepath=str(art/('stone_container_'+state+'.png'))
 bpy.ops.render.render(write_still=True)


