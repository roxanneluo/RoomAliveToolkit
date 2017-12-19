//functions that are needed for DepthMeshProcessing for KinectV2
float _Width;
float _Height;
int _TileHeight;

sampler2D _KinectDepthSource;
sampler2D _DepthToCameraSpaceX;
sampler2D _DepthToCameraSpaceY;
        
uniform float4x4 _CamToWorld;
uniform float4x4 _IRIntrinsics;
uniform float4x4 _RGBIntrinsics;	
uniform float4x4 _RGBExtrinsics;
uniform float4 _RGBDistCoef;
uniform float4 _IRDistCoef;

inline float2 Project_RGB(float3 pos) 
{ 
	//in the right handed coordinate system since all the camera calibration matrices are from the Kinect world
	float xp = pos[0] / pos[2];
	float yp = pos[1] / pos[2];
		 
	float fx = _RGBIntrinsics[0][0];
	float fy = _RGBIntrinsics[1][1];
	float cx = _RGBIntrinsics[0][2];
	float cy = _RGBIntrinsics[1][2];
	float k1 = _RGBDistCoef.x; //0.0f;
	float k2 = _RGBDistCoef.y; //0.0f;  
		    						
	// compute f(xp, yp)
	//float rSquared = xp * xp + yp * yp;
	//float xpp = xp * (1 + k1 * rSquared + k2 * rSquared * rSquared);
	//float ypp = yp * (1 + k1 * rSquared + k2 * rSquared * rSquared);
	float u = fx * xp + cx;
	float v = fy * yp + cy;
		
	u /= _Width;
	v /= _Height;

	//Why are we inverting coordinates here? (Benko)
	//It has nothing to do with camera math, but how the images are laid out in memory. 
	//In the image space x goes right, y goes top to bottom (i.e. down)
	//However in the Kinect camera space x goes left, y goes up and z goes forward (right handed coordinate system).
	//So to perform image lookup, we need to flip x and y. No other reason. 
	//u = 1 - u; //However, since kinect depth image is the flipped version of RGB, we would need to flip u one more time, so we instead don't flip it at all.  
	//v = 1 - v; 
		
	return float2(u,v);
}

inline float2 Project_IR(float3 pos)
{
	float xp = pos[0] / pos[2];
	float yp = pos[1] / pos[2];
		
	float fx = _IRIntrinsics[0][0];
	float fy = _IRIntrinsics[1][1];
	float cx = _IRIntrinsics[0][2];
	float cy = _IRIntrinsics[1][2];
	float k1 = _IRDistCoef.x; //0.0f;
	float k2 = _IRDistCoef.y; //0.0f; 
		    						
	// compute f(xp, yp)
	float rSquared = xp * xp + yp * yp;
	float xpp = xp * (1 + k1 * rSquared + k2 * rSquared * rSquared);
	float ypp = yp * (1 + k1 * rSquared + k2 * rSquared * rSquared);
	float u = fx * xpp + cx;
	float v = fy * ypp + cy;
		
	u /= _Width;
	v /= _Height;
	
	//see why we need to flip them in the function above
	u = 1 - u;
	v = 1 - v;	
	
	return float2(u,v);
}

#ifdef __DISPARITY_MAP__
// get depth from scaled disparity map
float _DisparityNumerator;
float _DisparityOffset;
inline float GetDepth(uint x, uint y)
{
	float4 c = tex2Dlod(_KinectDepthSource, float4(x / (_Width - 1), y / (_Height - 1), 0, 0));
	float dispIntensity = c.r;
	if (dispIntensity >= 1 - 1e-5)
		return 0;
	return _DisparityNumerator / (dispIntensity + _DisparityOffset);
}
#else

// get depth from depth map
//x and y is in pixels [0-511] and [0-423]
inline float GetDepth(uint x, uint y)
{
	float4 c = tex2Dlod(_KinectDepthSource, float4(x/(_Width - 1), y/(_Height - 1), 0, 0));
	
	return c.r; // c.r+2.1 when depth has offset
}
#endif

inline float3 Unproject_IR(float3 image)
{
	float fx = _IRIntrinsics[0][0];
	float fy = _IRIntrinsics[1][1];
	float cx = _IRIntrinsics[0][2];
	float cy = _IRIntrinsics[1][2];
	float k1 = _IRDistCoef.x; //0.0f;
	float k2 = _IRDistCoef.y; //0.0f; 
	
	float z = image.z;
	float x = (image.x - cx) / fx * z;
	float y = (image.y - cy) / fy * z;

	return float3(x, y, z);
}
		
inline float3 CameraToWorld(float3 pos)
{
	float4 depthPt = float4(pos.x, pos.y, pos.z, 1);
	float4 worldPos = mul(_CamToWorld, depthPt);
	float x = worldPos.x / worldPos.w;
	float y = worldPos.y / worldPos.w;
	float z = worldPos.z / worldPos.w;
	return float3(x, y, z);
}

inline float3 ComputeFace(in float2 texCoord, out float3 posA, out float3 posB, out float2 uv)
{
		uint tile = (uint) texCoord.y;
		uint id = (uint) texCoord.x;
		uint tileWidth = _Width - 1;
		uint pointsPerQuad = 6;
		id = id + ((tileWidth) * _TileHeight * pointsPerQuad) * tile;
		  	
		// each quad is 6 vertices
		uint q = id / pointsPerQuad;
		
		// position of quad
		uint qx = q % (tileWidth);
		uint qy = q / (tileWidth);
		
		// vertex in quad
		uint v = id % pointsPerQuad;
		
		// position of vertex in quad
		uint vx, vy;
		
		// position of other vertices on the triangle, used for computing normals and 
		// testing that all depth values in the triangle are valid
		// assign a and b according to right hand rule, so that a x b gives us our normal
		uint ax, ay, bx, by;

		if(v == 0)
		{
			vx = 0; vy = 0;
		
			ax = 1; ay = 0; // 1
			bx = 0; by = 1; // 2
		}
			
		if(v == 1)
		{
			vx = 1; vy = 0;
		
			ax = 0; ay = 1; // 2
			bx = 0; by = 0; // 0
		}
			
		if(v == 2)
		{
			vx = 0; vy = 1;
		
			ax = 0; ay = 0; // 0
			bx = 1; by = 0; // 1
		}

		if(v == 3)
		{
			vx = 1; vy = 1;
		
			ax = 0; ay = 1; // 4
			bx = 1; by = 0; // 5
		} 
			
		if(v == 4)
		{ 
			vx = 0; vy = 1;
		
			ax = 1; ay = 0; // 5
			bx = 1; by = 1; // 3
		}
			
		if(v == 5)
		{
			vx = 1; vy = 0;
		
			ax = 1; ay = 1; // 3
			bx = 0; by = 1; // 4
		}
			
		//flip x because the depth images and the depthToCameraTable are flipped horizontally
		/*
		float x = tileWidth - (qx + vx);
		float xa = tileWidth - (qx + ax);
		float xb = tileWidth - (qx + bx);
		*/

		//if the depth images are not flipped
		float x = qx + vx;
		float y = qy + vy;
		float xa = qx + ax;
		float xb = qx + bx;

		float depth = GetDepth(x, y);
		float3 pos = Unproject_IR(float3(x, y, depth));
		uv = float2(x / _Width, y / _Height);

		float depthA = GetDepth( xa, qy + ay );
		posA = Unproject_IR(float3(xa, qy + ay, depthA));

		float depthB = GetDepth( xb, qy + by );
		posB = Unproject_IR(float3(xb, qy + by, depthB));

		return pos;
}

/*************************************
 * functions that I want to use within shader but will
 * be shared by DepthMesh and DisparityMesh shaders
 *************************************/
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
v2f vert(appdata inputV)
{
	//UNITY_INITIALIZE_OUTPUT(Input,o);

	float3 posA = float3(0, 0, 0);
	float3 posB = float3(0, 0, 0);
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