using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace Telepresence {
    [AddComponentMenu("Telepresence/DepthMeshCreator")]
    public class DepthMeshCreator : MonoBehaviour
    {
        public Material surfaceMaterial;
        public Texture2D rgbTexture;
        public Texture2D depthTexture;

        // Unity cannot render one full mesh due to number of triangles limit, so this splits it into segments to be rendered separately. 
        // width of depth map patch to generate each submesh. I assume it's depthTexture.width
        [RoomAliveToolkit.ReadOnly] public int depthWidth = 512;
        // height of depth map patch to generate each submesh
        public int depthHeight = 1;//6;
        // number of depth map tiles in x direction to generate submesh
        [RoomAliveToolkit.ReadOnly] public int divTilesX = 1;
        // number of depth map tiles in y direction to generate submesh
        [RoomAliveToolkit.ReadOnly] public int divTilesY = 424;
        private int numTiles;

        private Mesh[] meshes;
        private MeshFilter[] meshFilters;
        private MeshRenderer[] meshRenderers;

        private GameObject[] gameObjects;

        // Use this for initialization
        protected virtual void Start()
        {
            // Copy material. so that modification to the original material on disk
            // or in program won't affect each other. But note that each submesh shares
            // the same material. So changes to it would affect all submeshes.
            surfaceMaterial = new Material(surfaceMaterial);

            UpdateMaterials();
            CreateResources();
        }

        void Update()
        {
            UpdateMaterials();
        }

        // This should be changed if intrinsics of camera is changed. 
        // (At least it has to be changed when size of the image is changed)
        virtual protected Matrix4x4 CreateIntrinsics()
        {
            Matrix4x4 mat = Matrix4x4.identity;
            mat[0, 0] = 366.58111130396549f;
            mat[1, 1] = 366.60331396606972f;
            mat[0, 2] = 255.29612916213162f;
            mat[1, 2] = 222.20030247747795f;
            mat[3, 3] = 0;
            return mat;
        }

        virtual protected void UpdateMaterials()
        {
            Matrix4x4 intrinsics = CreateIntrinsics();

            surfaceMaterial.SetMatrix("_IRIntrinsics", intrinsics);
            /*
            surfaceMaterial.SetMatrix("_RGBIntrinsics", intrinsics);
            surfaceMaterial.SetMatrix("_RGBExtrinsics", Matrix4x4.identity);
            surfaceMaterial.SetMatrix("_CamToWorld", Matrix4x4.identity); //formerly kinectClient.localToWorld, now incorperated in transform
            */
            surfaceMaterial.SetTexture("_MainTex", rgbTexture);
            surfaceMaterial.SetTexture("_KinectDepthSource", depthTexture);
            surfaceMaterial.SetFloat("_Width", depthTexture.width);
            surfaceMaterial.SetFloat("_Height", depthTexture.height);
            surfaceMaterial.SetInt("_TileHeight", depthHeight);
            // FIXME
            //surfaceMaterial.SetTexture("_DepthToCameraSpaceX", depthToCameraSpaceX);
            //surfaceMaterial.SetTexture("_DepthToCameraSpaceY", depthToCameraSpaceY);
        }

        // Set divTilesX, divTilesY, and depthWidth based on depthTexture.width and depthHeight
        // I need to ensure that divTilesY * depthHeight == depthTexture.height and return false
        // if this is not satisfied. Here, I'm being lazy and just set depthHeight = 1 so that this
        // is guaranteed to be true. Actually, I observed it's faster when depthHeight is smaller 
        //since it reduces the time to generate the shared dummy submesh.
        private bool setTileParameters()
        {
            depthWidth = depthTexture.width;
            divTilesX = 1;
            divTilesY = (int)Mathf.Ceil(depthTexture.height / (float)depthHeight);
            return true;
        }

        private void CreateResources()
        {
            if (!setTileParameters()) return;

            int numPoints = (depthWidth - 1) * (depthHeight) * 6;

            numTiles = divTilesX * divTilesY;
            var verts = new Vector3[numPoints];
            for (var i = 0; i < numPoints; ++i)
            {

                /*{
                    // debug: create a rough representation of the image plane.
                    int id = i / 6;
                    int r = id / (depthWidth - 1), c = id % (depthWidth - 1);
                    int q = i % 6;
                    float dx = 0.01f, dy = 0.1f;
                    float xx = 0, yy = 0;
                    switch (q)
                    {
                        case 1: yy = 1; break;
                        case 2: xx = 1; break;
                    }
                    verts[i] = new Vector3((c + xx) * dx, (r + yy) * dy, 0f);
                }*/

                verts[i] = new Vector3(0f, 0f, 0.0f);
            }

            var indices = new int[numPoints];
            for (var i = 0; i < numPoints; ++i)
                indices[i] = i;

            var texCoords = new Vector2[numPoints];
            for (var i = 0; i < numPoints; ++i)
            {
                texCoords[i].x = (float)(i);// + 0.001f);
            }

            var normals = new Vector3[numPoints];
            for (var i = 0; i < numPoints; ++i)
            {
                normals[i] = new Vector3(0.0f, 1.0f, 0.0f);
            }

            meshes = new Mesh[numTiles];
            meshFilters = new MeshFilter[numTiles];
            meshRenderers = new MeshRenderer[numTiles];

            gameObjects = new GameObject[numTiles];

            for (int i = 0; i < numTiles; i++)
            {
                // id
                for (var texIndex = 0; texIndex < numPoints; ++texIndex)
                {
                    texCoords[texIndex].y = (float)(i);// + .001f);
                }

                gameObjects[i] = new GameObject("Depth SubMesh");
                gameObjects[i].layer = gameObject.layer;

                gameObjects[i].transform.parent = transform;
                gameObjects[i].transform.localPosition = Vector3.zero;
                gameObjects[i].transform.localRotation = Quaternion.identity;
                gameObjects[i].transform.localScale = Vector3.one;

                meshFilters[i] = (MeshFilter)gameObjects[i].AddComponent(typeof(MeshFilter));
                meshRenderers[i] = (MeshRenderer)gameObjects[i].AddComponent(typeof(MeshRenderer));

                meshes[i] = new Mesh();
                meshes[i].vertices = verts;
                meshes[i].subMeshCount = 1;
                meshes[i].uv = texCoords;
                meshes[i].normals = normals;


                meshes[i].SetIndices(indices, MeshTopology.Triangles, 0);

                //float bounds = 100;
                //meshes[i].bounds = new Bounds(new Vector3(0, 0, 0), new Vector3(bounds, bounds, bounds));

                meshFilters[i].mesh = meshes[i];
                meshRenderers[i].enabled = true;

                //materials get updated every frame for every mesh
                meshRenderers[i].material = surfaceMaterial; //default material 
                //meshRenderers[i].receiveShadows = receiveShadows;
                //meshRenderers[i].shadowCastingMode = castShadows ? UnityEngine.Rendering.ShadowCastingMode.On : UnityEngine.Rendering.ShadowCastingMode.Off;

            }
        }
    }

}
 
