﻿
// Fra https://docs.unity3d.com/Manual/SL-VertexFragmentShaderExamples.html
//https://msdn.microsoft.com/en-us/library/windows/desktop/bb509640(v=vs.85).aspx
//https://msdn.microsoft.com/en-us/library/windows/desktop/ff471421(v=vs.85).aspx
// rand num generator http://gamedev.stackexchange.com/questions/32681/random-number-hlsl
// http://www.reedbeta.com/blog/2013/01/12/quick-and-easy-gpu-random-numbers-in-d3d11/
// https://docs.unity3d.com/Manual/RenderDocIntegration.html
// https://docs.unity3d.com/Manual/SL-ShaderPrograms.html

Shader "Unlit/SingleColor"
{
		SubShader{ Pass	{
			
	CGPROGRAM
		#pragma vertex vert
		#pragma fragment frag

		typedef vector <float, 3> vec3;  // to get more similar code to book
		typedef vector <fixed, 3> col3;
	
	struct appdata
	{
		float4 vertex : POSITION;
		float2 uv : TEXCOORD0;
	};

	struct v2f
	{
		float2 uv : TEXCOORD0;
		float4 vertex : SV_POSITION;
	};
	
	v2f vert(appdata v)
	{
		v2f o;
		o.vertex = UnityObjectToClipPos(v.vertex);
		o.uv = v.uv;
		return o;
	}
	


////////////////////////////////////////////////////////////////////////////////////////////////////////

		struct Ray
	{
	    vec3 origin;
	    vec3 direction;
	};

	Ray MakeRay(float3 origin, float3 direction)
	{
	    Ray r;
	    r.origin = origin;
	    r.direction = direction;
	    return r;
	}

	float3 PointAt(Ray ray, float t)
	{
	    return ray.origin + t * ray.direction;
	}

	bool hit_sphere(vec3 center, float radius, Ray r)
	{
		vec3 oc = center - r.origin;
		float a = dot(r.direction, r.direction);
		float b = -2.0 * dot(r.direction, oc);
		float c = dot(oc,oc) - radius*radius;
		float discriminant = b*b - 4*a*c;
		return (discriminant >= 0);
	}
		

	fixed4 frag(v2f i) : SV_Target
	{

		vec3 lower_left_corner = {-2, -1, -1};
		vec3 horizontal = {4, 0, 0};
		vec3 vertical = {0, 2, 0};
		vec3 origin = {0, 0, 0};
		
		float x = i.uv.x;
		float y = i.uv.y;

		Ray r = MakeRay(origin, lower_left_corner + x*horizontal + y*vertical);
		
		if (hit_sphere(vec3(0,0,-1),0.5, r))
		{
			return fixed4(col3(1,0,0),1);
		}
		
		float a = 0.5*(y+1.0);
		col3 col = (1.0 - a)*col3(1.0,1.0,1.0)+a*col3(0.5,0.7,1.0);

		return fixed4(col,1); 
	}

	
////////////////////////////////////////////////////////////////////////////////////


ENDCG

}}}