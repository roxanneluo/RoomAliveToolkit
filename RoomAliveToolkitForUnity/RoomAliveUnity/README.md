To use the project, actually for images of different sizes, their intrinisics matrix needs to be reset and some depth map have offset in depth. So `CreateIntrinsics()` in `DepthMesh/Scripts/DepthMeshCreator.cs` and `GetDepth()` in `DepthMesh/Shaders/DepthMeshProcessing.cginc` need to be modified. 


I included 2 versions to render scene from depth map/disparity map. 

1. using geometry shader to reject bad triangles (default).
    - +: It's more efficient this way since I do not need to generate 6 times more vertices and compute 2 more vertex in each vertex shader
    - -: In unity geometry shader does not work with surface shader. 
2. without geometry shader, generate duplicate vertices (3 vertices per triangle or 6 vertices per quad). 
    - +: I can combine surface shader this way.
    - -: Less efficient

   One can switch back to this version by switching to use `DepthMeshCreatorNoGeometryShader` and let `DisparityMeshCreator` to inherit it.
   And in the shader, follow the comments to include `DepthMeshProcessingNoGeometryShader.cginc` instead and remove `#programa geometry geom`. 
   Optional: It's better to set depthHeight=1
