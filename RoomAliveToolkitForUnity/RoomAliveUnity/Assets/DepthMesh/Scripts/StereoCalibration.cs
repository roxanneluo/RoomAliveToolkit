using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace Telepresence
{
    [System.Serializable]
    public class StereoCalibration
    {
        /*
         * z = baseline * focalLength / (disparity + doffs)
         */    
        public float doffs = 0f; // x-difference of principal points, doffs=cx1-cx0
        public float baseline = 1f;
        public float focalLength = 1f;
        public Vector2 leftPrincipalPoint = Vector2.zero;    // (cx0, cy0)
        
        // resize the Image by ratio in both x and y
        public static StereoCalibration Resize(StereoCalibration calib, float ratio)
        {
            StereoCalibration result = new StereoCalibration();
            result.doffs = calib.doffs * ratio;
            result.focalLength = calib.focalLength * ratio;
            result.leftPrincipalPoint = calib.leftPrincipalPoint * ratio;
            // only baseline is not rescaled
            result.baseline = calib.baseline;
            return result;
        }

        // disp = dispScale * d + dispOffset;
        // so z = baseline * focalLength / (dispScale * d + dispOffset + doffs)
        //      = numerator/(d+offset)
        // where numerator = baseline * foalLength/dispScale, and offset = (dispOffset + doffs)/dispScale
        // return Vector2(numerator, offset)
        public Vector2 DisparityPixelToDepthTransform(float dispScale = 1, float dispOffset = 0)
        {
            float numerator = baseline * focalLength;
            float offset = doffs;
            numerator /= dispScale;
            offset = (offset + dispOffset) / dispScale;
            return new Vector2(numerator, offset);
        }

        public Vector2 RightPrincipalPoint()
        {
            return leftPrincipalPoint + new Vector2(doffs, 0);
        }

        public Matrix4x4 Intrinsics(bool left = true)
        {
            Matrix4x4 mat = Matrix4x4.zero;
            mat[0, 0] = mat[1,1] = focalLength;
            mat[2, 2] = 1;

            Vector2 principalPoint = left ? leftPrincipalPoint : RightPrincipalPoint();
            mat[0, 2] = principalPoint.x;
            mat[1, 2] = principalPoint.y;
            return mat;
        }
    }
}
