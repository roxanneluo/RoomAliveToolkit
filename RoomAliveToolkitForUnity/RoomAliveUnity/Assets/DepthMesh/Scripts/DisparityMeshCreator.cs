using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace Telepresence
{
    [AddComponentMenu("Telepresence/DisparityMeshCreator")]
    public class DisparityMeshCreator : DepthMeshCreator
    {
        public StereoCalibration calib;
        // disparity = x*dispMapPixelIntensity+y;
        public Vector2 pixelToDisparityTransform = new Vector2(1, 0);
        public float imResizeRatio = 1;
        public bool left = true;

        protected override void Start()
        {
            calib = StereoCalibration.Resize(calib, imResizeRatio);
            base.Start();
        }

        protected override Matrix4x4 CreateIntrinsics()
        {
            return calib.Intrinsics(left);
        }
        protected override void UpdateMaterials()
        {
            base.UpdateMaterials();

            Vector2 pixToDepthTransform = calib. DisparityPixelToDepthTransform(
                pixelToDisparityTransform.x, pixelToDisparityTransform.y);
            surfaceMaterial.SetFloat("_DisparityNumerator", pixToDepthTransform.x);
            surfaceMaterial.SetFloat("_DisparityOffset", pixToDepthTransform.y);
        }
        
    }

}