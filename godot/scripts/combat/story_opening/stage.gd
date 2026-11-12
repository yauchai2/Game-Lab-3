extends Node3D
## Procedural set for the boot story opening: street corner, viaduct and train,
## repair garage, flight case and the collectors' car. Local metres; garage door faces +Z.
## Presentation only: no collision, AI, damage or save data.
const INK:=Color("14101e")
const SKY:=Color("f5129a")
const CYAN:=Color("27e6ee")
var mats:Dictionary={}
var rng:=RandomNumberGenerator.new()
var train:Node3D
var car:Node3D
var car_doors:Array[Node3D]=[]
var car_wheels:Array[Node3D]=[]
var case_root:Node3D
var case_lid:Node3D
var case_latches:Array[Node3D]=[]
var case_glow:MeshInstance3D
var table_props:Array[Node3D]=[]
var table_rest:Array[Vector3]=[]
var tubes:Array[MeshInstance3D]=[]
var tube_material:StandardMaterial3D
var speaker_cone:Node3D
var cup:Node3D
var wrench:Node3D
var bike:Node3D
var walkers:Array[Dictionary]=[]
var ledge:Node3D
var interior_lights:Array[OmniLight3D]=[]
var sun:DirectionalLight3D
const TABLE:=Vector3(.3,.95,-5.2)
## Reference video is a dusk street and a grimy garage: lit colours are pulled down by this factor.
const TONE:=.72

func mat(color:Color,unlit:=false,texture:Texture2D=null,tile:=1.0) -> StandardMaterial3D:
	var key:=str(color)+str(unlit)+str(texture)+str(tile)
	if mats.has(key):return mats[key]
	var m:=StandardMaterial3D.new();m.albedo_color=color if unlit else Color(color.r*TONE,color.g*TONE,color.b*TONE,color.a);m.roughness=1.0;m.metallic_specular=0.0
	if unlit:m.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	if texture!=null:
		m.albedo_texture=texture;m.texture_filter=BaseMaterial3D.TEXTURE_FILTER_NEAREST
		m.uv1_triplanar=true;m.uv1_world_triplanar=true;m.uv1_scale=Vector3.ONE/tile
	mats[key]=m;return m

func box(parent:Node3D,at:Vector3,size:Vector3,material:Material) -> MeshInstance3D:
	var shape:=BoxMesh.new();shape.size=size
	var node:=MeshInstance3D.new();node.mesh=shape;node.position=at;node.material_override=material
	parent.add_child(node);return node

func cyl(parent:Node3D,at:Vector3,radius:float,height:float,material:Material,sides:=8,top:=-1.0) -> MeshInstance3D:
	var shape:=CylinderMesh.new();shape.bottom_radius=radius;shape.top_radius=radius if top<0 else top
	shape.height=height;shape.radial_segments=sides;shape.rings=1
	var node:=MeshInstance3D.new();node.mesh=shape;node.position=at;node.material_override=material
	parent.add_child(node);return node

func group(parent:Node3D,at:Vector3,label:String) -> Node3D:
	var node:=Node3D.new();node.name=label;node.position=at;parent.add_child(node);return node

func _facade(wall:Color,lit:Color,dark:Color,seed_value:int) -> ImageTexture:
	# 8x8 flats per 24 m tile; grime rows and a few lit rooms. Never text.
	var local:=RandomNumberGenerator.new();local.seed=seed_value
	var image:=Image.create(128,128,false,Image.FORMAT_RGB8)
	for y in 128:
		for x in 128:
			var grime:=.86+.14*local.randf()
			if y%16==15:grime*=.62
			image.set_pixel(x,y,Color(wall.r*grime,wall.g*grime,wall.b*grime))
	for row in 8:
		for column in 8:
			var glass:=lit if local.randf()<.34 else dark
			if local.randf()<.08:glass=Color("ff5fb4")
			for y in range(4,12):
				for x in range(3,13):
					var edge:=x==3 or x==12 or y==4 or y==11 or x==8
					image.set_pixel(column*16+x,row*16+y,dark.darkened(.4) if edge else glass)
			if local.randf()<.3:
				for x in range(5,11):image.set_pixel(column*16+x,row*16+13,Color("9a9aa6"))
	return ImageTexture.create_from_image(image)

func _mosaic(seed_value:int) -> ImageTexture:
	# Sticky notes and mosaic stickers over grey plaster, as on the reference garage columns. Never text.
	var local:=RandomNumberGenerator.new();local.seed=seed_value
	var image:=Image.create(64,64,false,Image.FORMAT_RGB8)
	for cy in 16:
		for cx in 16:
			var g:=local.randf_range(.35,.75);var c:=Color(g,g*.98,g*1.02)
			var roll:=local.randf()
			if roll<.14:c=Color("f0d94a").darkened(local.randf_range(0,.25))
			elif roll<.22:c=Color("e0146f").darkened(local.randf_range(.1,.4))
			elif roll<.27:c=Color("f3efe6")
			for y in 4:
				for x in 4:image.set_pixel(cx*4+x,cy*4+y,c)
	return ImageTexture.create_from_image(image)

func _rust() -> ImageTexture:
	var noise:=FastNoiseLite.new();noise.seed=7;noise.frequency=.09
	var image:=Image.create(64,64,false,Image.FORMAT_RGB8)
	for y in 64:
		for x in 64:
			var n:=noise.get_noise_2d(x,y)*.5+.5
			var c:=Color("3a2a22").lerp(Color("b5703c"),smoothstep(.25,.8,n))
			if (noise.get_noise_2d(x*3.1,y*3.1+40)>.45):c=c.darkened(.45)
			image.set_pixel(x,y,c)
	return ImageTexture.create_from_image(image)

func _starburst() -> ImageTexture:
	var image:=Image.create(64,64,false,Image.FORMAT_RGB8)
	for y in 64:
		for x in 64:
			var a:=atan2(y-32.0,x-32.0);var r:=Vector2(x-32.0,y-32.0).length()
			var c:=Color("ff3d97") if int((a+PI)/TAU*20.0)%2==0 else Color("fbe9f2")
			if r<9.0:c=Color("fff3a8")
			if x<2 or y<2 or x>61 or y>61:c=Color("1a1420")
			image.set_pixel(x,y,c)
	return ImageTexture.create_from_image(image)

func build() -> void:
	rng.seed=20261112
	var asphalt:=mat(Color("8c8794"),false,preload("res://assets/textures/road_asphalt_128.png"),4.0)
	var paving:=mat(Color("b9b3bf"),false,preload("res://assets/textures/sidewalk_tiles_128.png"),3.0)
	var concrete:=mat(Color("a7a2ad"),false,preload("res://assets/textures/painted_concrete_128.png"),4.0)
	var plaster:=mat(Color("b8b0b4"),false,preload("res://assets/textures/corner_plaster_128.png"),4.0)
	var shutter:=mat(Color("9d9aa8"),false,preload("res://assets/textures/corner_shutter_128.png"),3.0)
	var tiles:=mat(Color("c9c2c0"),false,preload("res://assets/textures/corner_tiles_128.png"),3.0)
	var facades:Array[StandardMaterial3D]=[
		mat(Color.WHITE,false,_facade(Color("8f8b97"),Color("ffe9a8"),Color("2a2633"),11),24.0),
		mat(Color.WHITE,false,_facade(Color("6f6a78"),Color("fff3c9"),Color("1d1a26"),23),24.0),
		mat(Color.WHITE,false,_facade(Color("a9a3a6"),Color("ffd98a"),Color("302a36"),37),24.0)]
	var dark:=mat(Color("26222e"));var steel:=mat(Color("5d5a68"));var black:=mat(INK)
	sun=DirectionalLight3D.new();sun.rotation_degrees=Vector3(-52,-38,0);sun.light_color=Color("ffc2dc");sun.light_energy=.85
	sun.shadow_enabled=false;add_child(sun)
	# Ground: garage apron, near pavement, road, far pavement.
	box(self,Vector3(0,-.25,9),Vector3(260,.26,12),asphalt)
	box(self,Vector3(0,-.1,1.5),Vector3(260,.2,3),paving)
	box(self,Vector3(0,-.1,16.5),Vector3(260,.2,3),paving)
	box(self,Vector3(0,-.2,30),Vector3(260,.2,26),concrete)
	for i in 7:box(self,Vector3(11.0+i*.0,-.11,4.2+i*1.5),Vector3(3.4,.02,.7),mat(Color("efe9da")))
	for i in 26:box(self,Vector3(-125.0+i*10,-.11,9),Vector3(3.2,.02,.16),mat(Color("f0d94a")))
	for x in [-9.0,-6.5,6.5,9.0,14.5]:
		cyl(self,Vector3(x,.45,2.7),.11,.9,mat(Color("e9c531")),6)
		cyl(self,Vector3(x,.74,2.7),.115,.14,black,6)
	_viaduct(concrete,steel,dark)
	_city(facades,dark)
	_garage(concrete,plaster,shutter,tiles,facades[0],dark,steel)
	_street_dressing(steel,dark)
	_garage_clutter(steel,dark)
	_street_signals(steel,dark)
	_case()
	_car()
	_walkers()
	# Rooftop ledge for the title silhouettes: cyan cap like the storyboard.
	ledge=group(self,Vector3(-1.5,27.0,-2.0),"TitleLedge")
	box(ledge,Vector3(0,-.5,0),Vector3(12,1.0,2.4),mat(Color("17131f")))
	box(ledge,Vector3(0,.04,1.05),Vector3(12.2,.12,.34),mat(CYAN,true))
	for x in [-5.6,5.6]:box(ledge,Vector3(x,-.25,1.25),Vector3(.5,.5,.2),mat(Color("3a3644")))

func _viaduct(concrete:Material,steel:Material,dark:Material) -> void:
	var root:=group(self,Vector3(0,0,20.5),"Viaduct")
	box(root,Vector3(0,7.6,0),Vector3(260,1.2,5.4),concrete)
	box(root,Vector3(0,8.5,2.6),Vector3(260,.7,.2),steel)
	box(root,Vector3(0,8.5,-2.6),Vector3(260,.7,.2),steel)
	for i in 14:
		var x:=-126.0+i*19.4
		box(root,Vector3(x,3.5,0),Vector3(1.5,7.0,2.2),concrete)
		box(root,Vector3(x,6.7,0),Vector3(2.2,.6,5.0),dark)
	# Catenary masts and wires the first shot dives through.
	for i in 9:
		var x:=-76.0+i*19.0
		box(root,Vector3(x,10.6,2.4),Vector3(.16,3.6,.16),steel)
		box(root,Vector3(x,12.2,1.2),Vector3(.1,.1,2.6),steel)
	for z in [.2,1.9]:box(root,Vector3(0,12.1,z),Vector3(240,.045,.045),mat(INK,true))
	train=group(root,Vector3(0,8.2,0),"Train")
	var body:=mat(Color("c9c6d2"));var band:=mat(Color("d8206f"));var glow:=mat(Color("fff2bd"),true)
	for unit in 5:
		var carriage:=group(train,Vector3(unit*13.2-26.4,0,0),"Car%d"%unit)
		box(carriage,Vector3(0,1.75,0),Vector3(12.6,2.7,2.9),body)
		box(carriage,Vector3(0,.55,0),Vector3(12.7,.5,2.95),band)
		box(carriage,Vector3(0,3.2,0),Vector3(11.8,.25,2.3),dark)
		for w in 6:box(carriage,Vector3(-5.0+w*2.0,2.1,0),Vector3(1.5,.9,2.96),glow)
		for bogie in [-4.2,4.2]:box(carriage,Vector3(bogie,.12,0),Vector3(2.2,.4,2.2),dark)

func _city(facades:Array[StandardMaterial3D],dark:Material) -> void:
	var root:=group(self,Vector3.ZERO,"City")
	# Far side of the tracks, then both street ends and the garage side row.
	var rows:=[[-128.0,128.0,27.0,36.0,16.0,34.0],[-128.0,128.0,46.0,58.0,30.0,56.0],[-128.0,-9.5,-14.0,-1.0,12.0,34.0],[25.5,128.0,-14.0,-1.0,12.0,34.0],[-128.0,128.0,-34.0,-18.0,22.0,52.0]]
	for row in rows:
		var x:float=row[0]
		while x<row[1]-4.0:
			var width:=rng.randf_range(7.0,13.0);var depth:float=row[3]-row[2]
			var height:=rng.randf_range(row[4],row[5])
			var at:=Vector3(x+width*.5,height*.5,(row[2]+row[3])*.5)
			box(root,at,Vector3(width,height,depth),facades[rng.randi()%3])
			box(root,at+Vector3(0,height*.5+.15,0),Vector3(width+.3,.3,depth+.3),dark)
			if rng.randf()<.6:
				box(root,at+Vector3(rng.randf_range(-2,2),height*.5+1.2,0),Vector3(2.2,2.0,2.2),dark)
				box(root,at+Vector3(rng.randf_range(-3,3),height*.5+2.6,rng.randf_range(-2,2)),Vector3(.08,5.0,.08),dark)
			x+=width+rng.randf_range(.3,1.6)
	# The low shop whose roof carries the title ledge, with a magenta awning.
	box(root,Vector3(18,4.1,-7),Vector3(13.5,8.2,12.0),facades[2])
	box(root,Vector3(18,8.35,-7),Vector3(13.9,.3,12.4),dark)
	var awning:=box(root,Vector3(17,3.2,.7),Vector3(8.0,.12,1.9),mat(Color("e0146f")));awning.rotation_degrees.x=14
	var awning2:=box(root,Vector3(-14,3.3,.7),Vector3(6.0,.12,1.9),mat(Color("a01052")));awning2.rotation_degrees.x=14

func _garage(concrete:Material,plaster:Material,shutter:Material,tiles:Material,facade:Material,dark:Material,steel:Material) -> void:
	var root:=group(self,Vector3.ZERO,"Garage")
	box(root,Vector3(0,-.05,-4.6),Vector3(15,.1,9.6),mat(Color("8f8a92"),false,preload("res://assets/textures/painted_concrete_128.png"),3.0))
	box(root,Vector3(0,.012,-.6),Vector3(10,.02,.5),mat(Color("e9c531")))
	for i in 9:box(root,Vector3(-4.4+i*1.1,.014,-.6),Vector3(.45,.022,.5),mat(INK))
	box(root,Vector3(0,2.3,-9.2),Vector3(15,4.8,.4),plaster)
	box(root,Vector3(-7.3,2.3,-4.6),Vector3(.4,4.8,9.6),tiles)
	box(root,Vector3(7.3,2.3,-4.6),Vector3(.4,4.8,9.6),shutter)
	box(root,Vector3(0,4.75,-4.6),Vector3(15,.3,9.8),dark)
	var mosaic:=mat(Color.WHITE,false,_mosaic(5),1.2)
	for x in [-6.2,6.2]:box(root,Vector3(x,2.3,-.1),Vector3(2.4,4.8,.5),mosaic)
	box(root,Vector3(0,4.3,-.1),Vector3(15,.8,.5),concrete)
	# Rolled shutter drum and corrugated canopy over the door.
	box(root,Vector3(0,3.75,.25),Vector3(10.2,.45,.5),shutter)
	var canopy:=box(root,Vector3(0,4.9,1.1),Vector3(12,.1,2.6),steel);canopy.rotation_degrees.x=10
	box(root,Vector3(0,15.5,-5),Vector3(15.6,21,10.4),facade)
	box(root,Vector3(0,26.15,-5),Vector3(16,.3,10.8),dark)
	tube_material=StandardMaterial3D.new();tube_material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;tube_material.albedo_color=Color("fff9e2")
	for at in [Vector3(-2.6,4.45,-2.8),Vector3(2.6,4.45,-2.8),Vector3(0,4.45,-6.4)]:
		box(root,at+Vector3(0,.08,0),Vector3(2.5,.08,.32),steel)
		tubes.append(box(root,at,Vector3(2.3,.09,.14),tube_material))
	for at in [Vector3(-2.5,3.6,-3.0),Vector3(2.5,3.6,-5.5)]:
		var lamp:=OmniLight3D.new();lamp.position=at;lamp.omni_range=11.0;lamp.light_energy=1.7;lamp.light_color=Color("ffe9c4")
		lamp.shadow_enabled=false;root.add_child(lamp);interior_lights.append(lamp)
	# Back wall: pegboard, tools, shelves, poster, fan.
	box(root,Vector3(-3.6,2.5,-8.95),Vector3(4.6,2.2,.08),mat(Color("3c3744")))
	for i in 9:
		var tool_color:Color=[Color("d8d4de"),Color("e0146f"),Color("27e6ee")][i%3]
		box(root,Vector3(-5.5+i*.47,2.6+.18*sin(i*1.7),-8.88),Vector3(.09,.7+.25*cos(i*2.3),.05),mat(tool_color))
	for level in 4:
		box(root,Vector3(-6.4,.5+level*.85,-6.6),Vector3(1.0,.06,2.6),steel)
		for i in 4:box(root,Vector3(-6.4,.72+level*.85,-7.6+i*.62),Vector3(.5,.36,.4),mat([Color("7c5a3a"),Color("3e6f7a"),Color("93334d"),Color("c7b46a")][(i+level)%4]))
	for z in [-7.85,-5.35]:box(root,Vector3(-6.4,1.8,z),Vector3(1.0,3.5,.08),steel)
	var poster:=MeshInstance3D.new();var quad:=QuadMesh.new();quad.size=Vector2(1.7,1.7);poster.mesh=quad
	var poster_material:=StandardMaterial3D.new();poster_material.albedo_texture=_starburst()
	poster_material.texture_filter=BaseMaterial3D.TEXTURE_FILTER_NEAREST;poster_material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	poster.material_override=poster_material;poster.position=Vector3(2.4,2.7,-8.97);root.add_child(poster)
	box(root,Vector3(2.4,2.7,-8.99),Vector3(1.85,1.85,.03),mat(Color("1a1420")))
	cyl(root,Vector3(5.6,3.7,-8.9),.62,.16,steel,10).rotation_degrees.x=90
	cyl(root,Vector3(5.6,3.7,-8.8),.5,.05,dark,6).rotation_degrees.x=90
	# Centre bench the case lands on, with loose tools that jump.
	var bench:=group(root,Vector3(TABLE.x,0,TABLE.z),"Bench")
	box(bench,Vector3(0,.9,0),Vector3(2.6,.1,1.25),mat(Color.WHITE,false,_rust(),1.2))
	for corner in [Vector3(-1.2,.43,-.52),Vector3(1.2,.43,-.52),Vector3(-1.2,.43,.52),Vector3(1.2,.43,.52)]:box(bench,corner,Vector3(.1,.86,.1),steel)
	box(bench,Vector3(0,.3,0),Vector3(2.4,.05,1.05),steel)
	for spec in [[Vector3(-1.05,.99,-.38),Vector3(.34,.05,.07),Color("d8d4de")],[Vector3(-1.0,.99,.34),Vector3(.07,.05,.3),Color("e0146f")],[Vector3(1.08,1.02,.38),Vector3(.14,.12,.14),Color("27e6ee")],[Vector3(1.02,.99,-.4),Vector3(.3,.05,.06),Color("c7b46a")]]:
		var loose:=box(bench,spec[0],spec[1],mat(spec[2]));table_props.append(loose);table_rest.append(loose.position)
	# RIVET's bike, LOOP's speaker, HUSH's sofa.
	bike=group(root,Vector3(-3.9,0,-3.0),"Bike")
	for x in [-.82,.82]:
		var tyre:=MeshInstance3D.new();var torus:=TorusMesh.new();torus.inner_radius=.25;torus.outer_radius=.40;torus.rings=10;torus.ring_segments=5
		tyre.mesh=torus;tyre.material_override=mat(INK);tyre.position=Vector3(x,.40,0);tyre.rotation_degrees.x=90;bike.add_child(tyre)
		cyl(bike,Vector3(x,.40,0),.2,.07,steel,8).rotation_degrees.x=90
	box(bike,Vector3(.1,.82,0),Vector3(.72,.28,.34),mat(Color("d81f4f")))
	box(bike,Vector3(-.5,.86,0),Vector3(.66,.14,.3),mat(INK))
	box(bike,Vector3(0,.52,0),Vector3(.62,.36,.3),steel)
	box(bike,Vector3(-.45,.6,0),Vector3(.9,.08,.1),mat(Color("efe9da"))).rotation_degrees.z=-12
	box(bike,Vector3(.62,.86,0),Vector3(.08,.9,.08),steel).rotation_degrees.z=-24
	box(bike,Vector3(.48,1.22,0),Vector3(.08,.06,.66),steel)
	box(bike,Vector3(-.2,.16,.2),Vector3(.5,.04,.04),steel)
	wrench=group(root,Vector3.ZERO,"Wrench")
	box(wrench,Vector3(0,0,.13),Vector3(.045,.03,.34),mat(Color("d8d4de")))
	box(wrench,Vector3(0,0,.32),Vector3(.11,.035,.08),mat(Color("d8d4de")))
	var speaker:=group(root,Vector3(1.6,0,-2.7),"Speaker")
	box(speaker,Vector3(0,.55,0),Vector3(.8,1.1,.7),mat(Color("1d1a26")))
	speaker_cone=cyl(speaker,Vector3(0,.42,.36),.27,.06,mat(Color("4d4958")),10);speaker_cone.rotation_degrees.x=90
	cyl(speaker,Vector3(0,.42,.39),.11,.04,mat(CYAN,true),8).rotation_degrees.x=90
	cyl(speaker,Vector3(0,.86,.36),.1,.05,mat(Color("4d4958")),8).rotation_degrees.x=90
	for i in 4:box(root,Vector3(1.0-i*.32,.03,-2.2+.2*sin(i*2.0)),Vector3(.36,.04,.05),mat([Color("e0146f"),Color("f0d94a")][i%2])).rotation_degrees.y=i*23.0
	box(root,Vector3(.9,.2,-1.5),Vector3(.5,.4,.4),mat(Color("3a3644")))
	var sofa:=group(root,Vector3(4.6,0,-3.4),"Sofa")
	var leather:=mat(Color("7a4a34"));var patch:=mat(Color("5f3626"))
	box(sofa,Vector3(0,.3,0),Vector3(1.1,.5,2.3),leather)
	box(sofa,Vector3(.5,.75,0),Vector3(.3,.9,2.3),patch)
	for z in [-1.2,1.2]:box(sofa,Vector3(0,.5,z),Vector3(1.1,.75,.28),patch)
	box(sofa,Vector3(-.05,.57,.3),Vector3(.9,.05,.5),mat(Color("93334d")))
	cup=group(root,Vector3.ZERO,"Cup")
	cyl(cup,Vector3.ZERO,.045,.15,mat(Color("f3efe6")),7,.058)
	box(cup,Vector3(.01,.13,0),Vector3(.014,.16,.014),mat(Color("e0146f")))
	# Crates, stool and bin from the existing prop library (wrappers; GLBs untouched).
	for spec in [["res://scenes/PROP_CRATES_A01.tscn",Vector3(5.9,0,-7.6),0.0],["res://scenes/PROP_SHOP_STOOL_A01.tscn",Vector3(-2.2,0,-5.6),30.0],["res://scenes/PROP_BIN_A01.tscn",Vector3(6.3,0,-1.2),0.0],["res://scenes/PROP_CRATES_A01.tscn",Vector3(-6.3,0,-1.3),90.0]]:
		if not ResourceLoader.exists(spec[0]):continue
		var prop:Node3D=(load(spec[0]) as PackedScene).instantiate();prop.position=spec[1];prop.rotation_degrees.y=spec[2];root.add_child(prop)
		for body in prop.find_children("*","CollisionObject3D",true,false):body.process_mode=Node.PROCESS_MODE_DISABLED

func _street_dressing(steel:Material,dark:Material) -> void:
	var root:=group(self,Vector3.ZERO,"StreetDressing")
	for x in [-34.0,-12.0,12.5,36.0]:
		box(root,Vector3(x,5.2,2.2),Vector3(.2,10.4,.2),dark)
		box(root,Vector3(x,9.4,2.2),Vector3(.1,.1,2.2),dark)
		box(root,Vector3(x+.5,7.0,2.2),Vector3(.5,.7,.4),steel)
	for i in 3:
		var wire:=box(root,Vector3(0,9.5-i*.5,1.4+i*.5),Vector3(72,.04,.04),mat(INK,true));wire.rotation_degrees.z=.5-i*.4
	# Cross-street wires the dive passes between.
	for x in [-20.0,-6.0,9.0]:
		var span:=box(root,Vector3(x,10.2,11),Vector3(.04,.04,19),mat(INK,true));span.rotation_degrees.x=2.5
	# Bus shelter, vending machine, and blank signs (no text until supplied).
	var shelter:=group(root,Vector3(-17,0,15.8),"Shelter")
	box(shelter,Vector3(0,2.5,0),Vector3(5.0,.12,1.6),steel)
	for x in [-2.3,2.3]:box(shelter,Vector3(x,1.25,.6),Vector3(.1,2.5,.1),steel)
	box(shelter,Vector3(0,1.3,.7),Vector3(4.6,1.6,.06),mat(Color("efe6d2")))
	box(shelter,Vector3(0,.45,.2),Vector3(3.2,.1,.4),mat(Color("d81f4f")))
	box(root,Vector3(9.2,1.0,.45),Vector3(1.0,2.0,.7),mat(Color("3b6fd0")))
	box(root,Vector3(9.2,1.4,.82),Vector3(.8,.9,.04),mat(Color("dff4ff"),true))
	for spec in [[Vector3(-11.5,5.6,.9),Vector3(.3,2.6,1.1),Color("e0146f")],[Vector3(13.0,6.4,.9),Vector3(.3,3.2,1.0),Color("27e6ee")],[Vector3(-22,4.6,.9),Vector3(.3,1.8,1.4),Color("f0d94a")],[Vector3(28,5.0,.9),Vector3(.3,2.4,1.2),Color("e0146f")]]:
		box(root,spec[0],spec[1],mat(spec[2],true))
	for spec in [["res://scenes/VEH_CAR_A01.tscn",Vector3(-21,0,4.6),90.0],["res://scenes/VEH_VAN_A01.tscn",Vector3(30,0,13.2),-90.0],["res://scenes/PROP_HYDRANT_A01.tscn",Vector3(7.6,0,2.4),0.0],["res://scenes/PROP_MAILBOX_A01.tscn",Vector3(-8.2,0,1.0),180.0]]:
		if not ResourceLoader.exists(spec[0]):continue
		var prop:Node3D=(load(spec[0]) as PackedScene).instantiate();prop.position=spec[1];prop.rotation_degrees.y=spec[2];root.add_child(prop)
		for body in prop.find_children("*","CollisionObject3D",true,false):body.process_mode=Node.PROCESS_MODE_DISABLED

func _garage_clutter(steel:Material,dark:Material) -> void:
	# Small set dressing from the reference: bottles, boombox, drawer cabinet, cable, paper scraps, side table with bowl.
	var root:=group(self,Vector3.ZERO,"GarageClutter")
	var glass:=[mat(Color("3e8f5a")),mat(Color("c4852e")),mat(Color("8f3a4a"))]
	for level in 4:
		for i in 3:
			cyl(root,Vector3(-6.45+(i-1)*.28,.78+level*.85,-6.2-i*.55),.055,.26,glass[(i+level)%3],6,.03)
	var boombox:=group(root,Vector3(-6.4,2.55,-7.4),"Boombox")
	box(boombox,Vector3.ZERO,Vector3(.52,.26,.24),mat(Color("2a2733")))
	for x in [-.15,.15]:cyl(boombox,Vector3(x,0,.125),.08,.03,mat(Color("55515f")),8).rotation_degrees.x=90
	box(boombox,Vector3(0,.16,0),Vector3(.3,.03,.03),steel)
	var cabinet:=group(root,Vector3(-6.45,0,-3.0),"DrawerCabinet")
	box(cabinet,Vector3(0,.6,0),Vector3(.6,1.2,.9),mat(Color("5b5865")))
	for i in 4:box(cabinet,Vector3(.31,.2+i*.28,0),Vector3(.02,.2,.8),mat(Color("3a3745")))
	var side:=group(root,Vector3(4.6,0,-1.6),"SideTable")
	box(side,Vector3(0,.36,0),Vector3(.9,.06,.7),mat(Color("4a3a30")))
	for corner in [Vector3(-.4,.18,-.3),Vector3(.4,.18,-.3),Vector3(-.4,.18,.3),Vector3(.4,.18,.3)]:box(side,corner,Vector3(.05,.36,.05),steel)
	cyl(side,Vector3(-.12,.42,.05),.1,.05,mat(Color("2a2733")),8,.14)
	for i in 5:box(root,Vector3(-2.0+i*1.3,.012,-1.4-.9*(i%3)),Vector3(.3,.004,.22),mat(Color("e9e2d0"))).rotation_degrees.y=i*37.0
	for i in 3:
		var cable:=box(root,Vector3(-3.0+i*.6,.02,-8.5),Vector3(.04,.03,1.4),mat(INK));cable.rotation_degrees.y=18.0*i-12.0
	var rug:=box(root,Vector3(.2,.01,-1.9),Vector3(2.4,.012,1.0),mat(Color("c7b46a")))
	for i in 6:box(root,Vector3(-.85+i*.34,.017,-1.9),Vector3(.16,.004,1.02),mat(INK))
	for x in [-1.5,3.4]:
		var fan:=cyl(root,Vector3(x,3.6,-8.9),.5,.06,steel,10);fan.rotation_degrees.x=90

func _street_signals(steel:Material,dark:Material) -> void:
	var root:=group(self,Vector3.ZERO,"StreetSignals")
	var red:=mat(Color("ff2a2a"),true);var green:=mat(Color("38e872"),true)
	for spec in [[-12.0,6.0,red],[-4.5,12.4,green],[12.0,7.0,red],[3.5,12.4,red],[-26.0,6.5,green]]:
		var pole:=group(root,Vector3(spec[0],0,spec[1]),"Signal")
		box(pole,Vector3(0,2.6,0),Vector3(.12,5.2,.12),steel)
		box(pole,Vector3(0,4.9,.1),Vector3(.38,.95,.28),dark)
		box(pole,Vector3(0,5.15,.26),Vector3(.18,.18,.05),spec[2])
		box(pole,Vector3(0,4.75,.26),Vector3(.18,.18,.05),mat(Color("1a1a1a")))
	var small:=group(root,Vector3(-3.0,0,11.6),"RedCar")
	box(small,Vector3(0,.55,0),Vector3(3.8,.7,1.6),mat(Color("c01830")))
	box(small,Vector3(-.2,1.1,0),Vector3(2.0,.5,1.4),mat(Color("3a3550")))
	for x in [-1.2,1.2]:
		for z in [-.8,.8]:cyl(small,Vector3(x,.3,z),.3,.2,mat(INK),8).rotation_degrees.x=90
	box(small,Vector3(-1.92,.7,.5),Vector3(.04,.14,.3),mat(Color("ff2255"),true))
	box(small,Vector3(-1.92,.7,-.5),Vector3(.04,.14,.3),mat(Color("ff2255"),true))

func _case() -> void:
	# Black flight case. Lid hinges on the door side (+Z) so it opens toward the room.
	case_root=group(self,TABLE,"FlightCase")
	var shell:=mat(Color("1b1823"));var trim:=mat(Color("b9b6c4"));var foam:=mat(Color("0c0b10"))
	box(case_root,Vector3(0,.09,0),Vector3(1.5,.18,.78),shell)
	box(case_root,Vector3(0,.175,0),Vector3(1.4,.02,.68),foam)
	for x in [-.75,.75]:
		for z in [-.39,.39]:box(case_root,Vector3(x,.09,z),Vector3(.07,.2,.07),trim)
	for z in [-.39,.39]:box(case_root,Vector3(0,.18,z),Vector3(1.5,.025,.03),trim)
	# Two collector devices and the manifest: blocky, clearly props.
	var metal:=mat(Color("3d3a48"));var metal2:=mat(Color("555262"))
	for spec in [[Vector3(-.28,.2,.12),1.0],[Vector3(-.12,.2,-.17),.82]]:
		var gun:=group(case_root,spec[0],"Device");gun.scale=Vector3.ONE*spec[1]
		box(gun,Vector3(0,.02,0),Vector3(.62,.05,.12),metal)
		box(gun,Vector3(.42,.02,.005),Vector3(.3,.045,.075),metal2)
		box(gun,Vector3(-.2,.02,-.1),Vector3(.1,.05,.16),metal).rotation_degrees.y=14
		box(gun,Vector3(.02,.02,-.1),Vector3(.07,.05,.13),metal2)
		box(gun,Vector3(-.33,.02,.01),Vector3(.1,.05,.1),metal2)
		box(gun,Vector3(.1,.05,.01),Vector3(.2,.02,.03),mat(CYAN,true))
	for i in 3:box(case_root,Vector3(-.62,.2,-.2+i*.1),Vector3(.1,.04,.05),mat(Color("f0731c")))
	var sheet:=mat(Color("efe6d2"))
	for i in 3:box(case_root,Vector3(.47+i*.012,.19+i*.006,.02),Vector3(.3,.006,.42),sheet).rotation_degrees.y=-6+i*5.0
	for i in 6:box(case_root,Vector3(.46,.206,-.12+i*.055),Vector3(.2-.03*(i%3),.004,.016),mat(Color("77737f")))
	box(case_root,Vector3(.47,.206,.2),Vector3(.1,.008,.04),mat(Color("e0146f")))
	case_glow=box(case_root,Vector3(0,.2,0),Vector3(1.36,.01,.64),mat(Color(1,.95,.8,.0),true))
	var glow_material:=StandardMaterial3D.new();glow_material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	glow_material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA;glow_material.albedo_color=Color(1,.96,.82,0);case_glow.material_override=glow_material
	case_lid=group(case_root,Vector3(0,.18,.39),"Lid")
	box(case_lid,Vector3(0,.06,-.39),Vector3(1.5,.12,.78),shell)
	box(case_lid,Vector3(0,.005,-.39),Vector3(1.4,.02,.68),foam)
	for x in [-.75,.75]:
		for z in [-.78,0.0]:box(case_lid,Vector3(x,.06,z),Vector3(.07,.14,.07),trim)
	box(case_lid,Vector3(0,.125,-.39),Vector3(.5,.02,.06),trim)
	box(case_lid,Vector3(0,.15,-.39),Vector3(.34,.05,.05),shell)
	for x in [-.45,.45]:
		var latch:=group(case_root,Vector3(x,.17,-.4),"Latch")
		box(latch,Vector3(0,-.03,-.012),Vector3(.12,.1,.025),trim);case_latches.append(latch)

func pose_case(open:float,latch:float,glow:float) -> void:
	case_lid.rotation.x=deg_to_rad(108)*open
	for i in case_latches.size():case_latches[i].rotation.x=-deg_to_rad(95)*clampf(latch*2.0-i,0,1)
	(case_glow.material_override as StandardMaterial3D).albedo_color.a=glow

func _car() -> void:
	# Boxy black saloon built from primitives; doors swing for the synchronised exit.
	car=group(self,Vector3(60,0,6.4),"CollectorCar")
	var paint:=mat(Color("15131c"));var glass:=mat(Color("3a3550"));var chrome:=mat(Color("b9b6c4"))
	box(car,Vector3(0,.62,0),Vector3(4.7,.62,1.84),paint)
	box(car,Vector3(-.15,1.18,0),Vector3(2.5,.56,1.66),paint)
	box(car,Vector3(-.15,1.2,0),Vector3(2.3,.4,1.7),glass)
	box(car,Vector3(1.0,1.15,0),Vector3(.5,.45,1.5),glass).rotation_degrees.z=-38
	box(car,Vector3(-1.32,1.15,0),Vector3(.5,.45,1.5),glass).rotation_degrees.z=38
	box(car,Vector3(2.37,.52,0),Vector3(.1,.16,1.9),chrome)
	box(car,Vector3(-2.37,.52,0),Vector3(.1,.16,1.9),chrome)
	box(car,Vector3(2.37,.74,0),Vector3(.06,.2,1.1),chrome)
	for z in [-.7,.7]:
		box(car,Vector3(2.38,.76,z),Vector3(.05,.16,.3),mat(Color("fff5c4"),true))
		box(car,Vector3(-2.38,.76,z),Vector3(.05,.14,.36),mat(Color("ff2255"),true))
	for x in [-1.5,1.5]:
		for z in [-.93,.93]:
			var wheel:=cyl(car,Vector3(x,.36,z),.36,.24,mat(INK),10);wheel.rotation_degrees.x=90;car_wheels.append(wheel)
			cyl(wheel,Vector3(0,.13*signf(z),0),.2,.02,chrome,8)
	# Three doors on the kerb side (-Z) hinge at their front edge.
	for x in [.72,-.42]:
		var door:=group(car,Vector3(x,.62,-.93),"Door")
		box(door,Vector3(-.52,0,0),Vector3(1.04,.6,.06),paint)
		box(door,Vector3(-.52,.5,0),Vector3(.96,.36,.04),glass);car_doors.append(door)
	var far_door:=group(car,Vector3(.72,.62,.93),"Door")
	box(far_door,Vector3(-.52,0,0),Vector3(1.04,.6,.06),paint);box(far_door,Vector3(-.52,.5,0),Vector3(.96,.36,.04),glass);car_doors.append(far_door)

func pose_car(x:float,doors:float,dip:float) -> void:
	car.position=Vector3(x,-dip*.05,6.4);car.rotation.z=dip*.035
	for wheel in car_wheels:wheel.rotation.y=-x*2.6
	for i in car_doors.size():car_doors[i].rotation.y=deg_to_rad(64)*doors*(-1.0 if i<2 else 1.0)

func _walkers() -> void:
	# Blocky passers-by: enough life for the wide shots, never close-ups.
	var shirts:=[Color("d8206f"),Color("3b6fd0"),Color("f0d94a"),Color("efe9da"),Color("6f48b8"),Color("2f9c7a")]
	for i in 14:
		var person:=group(self,Vector3.ZERO,"Walker%d"%i)
		box(person,Vector3(0,.42,0),Vector3(.34,.84,.24),mat(Color("23202c")))
		box(person,Vector3(0,1.15,0),Vector3(.44,.66,.28),mat(shirts[i%6]))
		box(person,Vector3(0,1.66,0),Vector3(.28,.3,.28),mat(Color("d9a886")))
		box(person,Vector3(0,1.84,0),Vector3(.3,.1,.3),mat(INK))
		var lane:=1.6 if i%2==0 else 16.4
		var start:=rng.randf_range(-60,60)
		if lane<3.0 and absf(start)<12.0:start+=22.0*signf(start+.01)
		walkers.append({"node":person,"x":start,"z":lane+rng.randf_range(-.5,.5),"speed":rng.randf_range(.8,1.5)*(1 if i%3 else -1),"phase":rng.randf()*TAU})

func pose_walkers(t:float) -> void:
	for w in walkers:
		var x:float=wrapf(w.x+w.speed*t,-70.0,70.0)
		w.node.position=Vector3(x,.02+absf(sin(t*5.5+w.phase))*.05,w.z)
		w.node.rotation.y=PI*.5 if w.speed>0 else -PI*.5

func pose_train(t:float) -> void:
	train.position.x=58.0-t*27.0

func pose_table(jolt:float) -> void:
	for i in table_props.size():
		var lift:=maxf(0.0,sin(jolt*PI))*(.16+.05*i)
		table_props[i].position=table_rest[i]+Vector3(0,lift,0)
		table_props[i].rotation=Vector3(lift*3.0*(1 if i%2 else -1),0,lift*4.0)

func set_tube_flicker(level:float) -> void:
	tube_material.albedo_color=Color("fff9e2")*level
	for lamp in interior_lights:lamp.light_energy=1.7*level
