"""Build the single Milestone 1 shapeable rock; no gameplay or scene changes.

Run with Blender --background --python art/build_shapeable_rock.py.
Optional -- OUTPUT_DIRECTORY stages the blend, GLB and preview together.
"""
import bpy
import bmesh
import math
import random
import sys
from pathlib import Path
from mathutils import Vector

root = Path(__file__).resolve().parents[1]
staged = Path(sys.argv[sys.argv.index('--')+1]) if '--' in sys.argv else None
art = staged or root/'art'
models = staged or root/'assets/models'
art.mkdir(parents=True, exist_ok=True)
models.mkdir(parents=True, exist_ok=True)
bpy.ops.wm.read_factory_settings(use_empty=True)
rng = random.Random(713)
points=[]
# Broad asymmetric shoulders and a chipped crown, seated on a flat ground plane.
for count, radius, height, phase in [(10,.34,0,0),(13,.45,.23,.13),(11,.35,.52,.02),(7,.19,.66,.19)]:
    for i in range(count):
        angle=2*math.pi*i/count+phase+rng.uniform(-.05,.05)
        r=radius*rng.uniform(.90,1.06)
        z=0 if height==0 else height+rng.uniform(-.045,.025)
        points.append((r*math.cos(angle)+.035*height,
                       r*.89*math.sin(angle)-.045*height,z))
points.append((-.045,.015,.7))
mesh=bpy.data.meshes.new('ShapeableRock_FacetedStone')
bm=bmesh.new()
for p in points:bm.verts.new(p)
bmesh.ops.convex_hull(bm,input=list(bm.verts))
bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces))
bm.to_mesh(mesh)
bm.free()
mesh.update()
rock=bpy.data.objects.new('ShapeableRock',mesh)
bpy.context.collection.objects.link(rock)
# Stay within the existing 0.9 x 0.7 x 0.9 picking volume and occupancy radius.
for v in mesh.vertices:
    v.co.x=max(-.445,min(.445,v.co.x))
    v.co.y=max(-.445,min(.445,v.co.y))
    v.co.z=max(0,min(.7,v.co.z))
for i,factor in enumerate((.93,.97,1,1.025,1.05)):
    mat=bpy.data.materials.new('WarmSlate_'+str(i))
    mat.diffuse_color=(.29*factor,.285*factor,.265*factor,1)
    mat.use_nodes=True
    bsdf=mat.node_tree.nodes.get('Principled BSDF')
    bsdf.inputs['Base Color'].default_value=mat.diffuse_color
    bsdf.inputs['Roughness'].default_value=.94
    rock.data.materials.append(mat)
for face in mesh.polygons:
    face.use_smooth=False
    face.material_index=rng.choices(range(5),weights=[1,2,7,2,1])[0]
bpy.context.view_layer.objects.active=rock
rock.select_set(True)
rock['purpose']='Single Rock + Shapeable entity; yields one existing stone-club template.'
bpy.ops.wm.save_as_mainfile(filepath=str(art/'shapeable_rock.blend'))
bpy.ops.export_scene.gltf(filepath=str(models/'shapeable_rock.glb'),export_format='GLB',use_selection=True)
# Preview stage is intentionally absent from the saved model and exported GLB.
scene=bpy.context.scene
scene.render.engine='CYCLES'
scene.cycles.samples=24
scene.render.resolution_x=800
scene.render.resolution_y=650
scene.render.resolution_percentage=100
scene.world=bpy.data.worlds.new('PreviewWorld')
scene.world.use_nodes=True
scene.world.node_tree.nodes['Background'].inputs[0].default_value=(.22,.24,.28,1)
scene.world.node_tree.nodes['Background'].inputs[1].default_value=.5
bpy.ops.mesh.primitive_plane_add(size=200)
floor=bpy.context.object
floor_mat=bpy.data.materials.new('PreviewGround')
floor_mat.diffuse_color=(.12,.10,.075,1)
floor.data.materials.append(floor_mat)
for location,power,size in [((1,-2,3),180,3),((-2,1,2),100,2)]:
    bpy.ops.object.light_add(type='AREA',location=location)
    light=bpy.context.object
    light.data.energy=power
    light.data.shape='DISK'
    light.data.size=size
    light.rotation_euler=(Vector((0,0,.3))-light.location).to_track_quat('-Z','Y').to_euler()
bpy.ops.object.camera_add(location=(1.3,-1.8,1.1))
camera=bpy.context.object
camera.rotation_euler=(Vector((0,0,.32))-camera.location).to_track_quat('-Z','Y').to_euler()
camera.data.type='ORTHO'
camera.data.ortho_scale=1.35
scene.camera=camera
scene.render.filepath=str(art/'shapeable_rock_preview.png')
bpy.ops.render.render(write_still=True)
print('ROCK READY:',len(mesh.vertices),'vertices;',len(mesh.polygons),'facets')
