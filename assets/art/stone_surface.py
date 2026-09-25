"""Bake a subtle procedural stone albedo into a portable glTF texture."""
import bpy
import math

def apply_stone_texture(stone, output):
    objects=[o for o in bpy.context.scene.objects if o.type=='MESH' and any(m==stone for m in o.data.materials)]
    bpy.ops.object.select_all(action='DESELECT')
    for obj in objects:obj.select_set(True)
    bpy.context.view_layer.objects.active=objects[0]
    bpy.ops.object.mode_set(mode='EDIT')
    bpy.ops.mesh.select_all(action='SELECT')
    bpy.ops.uv.smart_project(angle_limit=math.radians(66),island_margin=.018)
    bpy.ops.object.mode_set(mode='OBJECT')
    image=bpy.data.images.new('ContainerStone_Albedo',width=1024,height=1024,alpha=False)
    image.colorspace_settings.name='sRGB'
    nodes=stone.node_tree.nodes;links=stone.node_tree.links
    bsdf=nodes.get('Principled BSDF');surface=next(n for n in nodes if n.type=='OUTPUT_MATERIAL')
    geometry=nodes.new('ShaderNodeNewGeometry')
    broad=nodes.new('ShaderNodeTexNoise');broad.inputs['Scale'].default_value=11
    broad.inputs['Detail'].default_value=3; broad.inputs['Roughness'].default_value=.7
    links.new(geometry.outputs['Position'],broad.inputs['Vector'])
    ramp=nodes.new('ShaderNodeValToRGB')
    ramp.color_ramp.elements[0].position=.18
    ramp.color_ramp.elements[0].color=(.21,.195,.17,1)
    ramp.color_ramp.elements[1].position=.82
    ramp.color_ramp.elements[1].color=(.40,.375,.335,1)
    links.new(broad.outputs['Fac'],ramp.inputs[0])
    grain=nodes.new('ShaderNodeTexNoise');grain.inputs['Scale'].default_value=320
    grain.inputs['Detail'].default_value=2
    links.new(geometry.outputs['Position'],grain.inputs['Vector'])
    mix=nodes.new('ShaderNodeMixRGB');mix.blend_type='MULTIPLY';mix.inputs[0].default_value=.23
    links.new(ramp.outputs[0],mix.inputs[1]);links.new(grain.outputs['Fac'],mix.inputs[2])
    emission=nodes.new('ShaderNodeEmission');links.new(mix.outputs[0],emission.inputs['Color'])
    links.new(emission.outputs[0],surface.inputs['Surface'])
    texture=nodes.new('ShaderNodeTexImage');texture.image=image;nodes.active=texture
    scene=bpy.context.scene;scene.render.engine='CYCLES';scene.cycles.samples=16
    scene.render.bake.margin=12;scene.render.bake.use_clear=True
    bpy.ops.object.bake(type='EMIT')
    for node in [geometry,broad,ramp,grain,mix,emission]:nodes.remove(node)
    links.new(texture.outputs['Color'],bsdf.inputs['Base Color'])
    links.new(bsdf.outputs['BSDF'],surface.inputs['Surface'])
    bsdf.inputs['Roughness'].default_value=.88
    image.filepath_raw=str(output/'stone_container_albedo.png');image.file_format='PNG';image.save();image.pack()
    texture.label='Baked mineral grain and soft stone mottling'
    bpy.ops.object.select_all(action='SELECT')
