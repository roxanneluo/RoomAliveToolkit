// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "Telepresence/DepthMeshShader(Unlit)" {
	Properties{
		_MainTex("Base (RGB)", 2D) = "black" {}
		_KinectDepthSource("Kinect Depth Source", 2D) = "black" {}
		_Width("Width", Float) = 512
		_Height("Height", Float) = 424
		_TileHeight("Tile Height", Int) = 8

		_DepthCuttofThreshold("Depth Cuttof Threshold", Range(0,2)) = 0.1
	}

	SubShader{
		Pass 
		{
			Tags{ "RenderType" = "Opaque" }

			Cull Front
			ZTest On
			CGPROGRAM
			#pragma vertex disp
			#pragma fragment frag


			//all other relevant variables are included in DepthMeshProcessing.cginc 
			#include "Assets/DepthMesh/Shaders/DepthMeshProcessing.cginc"
			struct appdata
			{
				float4 vertex : POSITION; // vertex position
				float2 uv : TEXCOORD0; // texture coordinate
			};

			struct v2f
			{
				float2 uv : TEXCOORD0; // texture coordinate
				float4 vertex : SV_POSITION; // clip space position
			};


			float _DepthCuttofThreshold;
			v2f disp(appdata inputV)
			{
				//UNITY_INITIALIZE_OUTPUT(Input,o);

				float3 posA = float3(0,0,0);
				float3 posB = float3(0,0,0);
				float2 uv = float2(0, 0);
				float3 pos = ComputeFace(inputV.uv, posA, posB, uv);

				// ***************************
				float d = _DepthCuttofThreshold;//0.1;
				if (length(posA - pos) > d || length(posB - pos) > d || length(posA - posB) > d)
					pos = 0;

				// ***************************
				// Return values
				// ***************************
				v2f o;
				float4 toMult = float4(pos.x, pos.y, pos.z, 1);
				o.vertex = UnityObjectToClipPos(toMult);
				o.uv = uv;
				return o;
			}


			sampler2D _MainTex;
			// pixel shader; returns low precision ("fixed4" type)
			// color ("SV_Target" semantic)
			fixed4 frag(v2f i) : SV_Target
			{
				// sample texture and return it
				fixed4 col = tex2D(_MainTex, i.uv);
			return col;
			}

			ENDCG
		}

		
	}
}
