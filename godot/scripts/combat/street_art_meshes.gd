extends RefCounted
## Original flat silhouettes, shared by balcony plants and street trees.
static func leaf_cluster() -> ArrayMesh:
    var surface:=SurfaceTool.new();surface.begin(Mesh.PRIMITIVE_TRIANGLES)
    surface.set_material(StandardMaterial3D.new())
    for plane in 3:
        var angle:float=plane*PI/3
        var points:Array[Vector3]=[Vector3(-.48,-.5,0),Vector3(-.3,.05,0),Vector3(-.45,.32,0),Vector3(-.12,.22,0),Vector3(.03,.55,0),Vector3(.18,.18,0),Vector3(.43,.39,0),Vector3(.3,.02,0),Vector3(.49,-.5,0)]
        var center:=Vector3(0,-.35,0)
        for i in points.size()-1:
            var tri:Array[Vector3]=[center,points[i],points[i+1]]
            for back in 2:
                for k in 3:
                    var vertex:Vector3=tri[k if back==0 else 2-k].rotated(Vector3.UP,angle)
                    surface.add_vertex(vertex)
    surface.generate_normals();return surface.commit()
static func crown() -> ArrayMesh:
    var s:=SurfaceTool.new();s.begin(Mesh.PRIMITIVE_TRIANGLES)
    s.set_material(StandardMaterial3D.new())
    var vertices:Array[Vector3]=[Vector3(0,.65,0),Vector3(.62,0,0),Vector3(0,0,.5),Vector3(-.55,.08,0),Vector3(0,-.45,0),Vector3(0,.07,-.58)]
    for triangle in [[0,1,2],[0,2,3],[0,3,5],[0,5,1],[4,2,1],[4,3,2],[4,5,3],[4,1,5]]:
        for i in triangle:s.add_vertex(vertices[i])
    s.generate_normals();return s.commit()
