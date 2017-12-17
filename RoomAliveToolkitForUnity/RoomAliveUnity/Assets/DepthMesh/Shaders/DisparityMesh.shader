// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "Telepresence/DisparityMeshShader(Unlit)" {
	Properties{
		_MainTex("Base (RGB)", 2D) = "black" {}
		_KinectDepthSource("Kinect Depth Source", 2D) = "black" {}
		_Width("Width", Float) = 512
		_Height("Height", Float) = 424
		_TileHeight("Tile Height", Int) = 8

		_DepthCuttofThreshold("Depth Cuttof Threshold", Range(0,2)) = 0.1

		// z = numerator/(d+offset)
		_DisparityNumerator("Disparity Numerator", Float) = 1
		_DisparityOffset("Disparity Offset", Float) = 0
	}

	SubShader{
		Pass 
		{
			Tags{ "RenderType" = "Opaque" }

			Cull Front
			ZTest On
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag


			#define __DISPARITY_MAP__
			//all other relevant variables are included in DepthMeshProcessing.cginc 
			#include "Assets/DepthMesh/Shaders/DepthMeshProcessing.cginc"
			

			ENDCG
		}

		
	}
}
