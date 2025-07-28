// Fra https://docs.unity3d.com/Manual/SL-VertexFragmentShaderExamples.html
//https://msdn.microsoft.com/en-us/library/windows/desktop/bb509640(v=vs.85).aspx
//https://msdn.microsoft.com/en-us/library/windows/desktop/ff471421(v=vs.85).aspx
// rand num generator http://gamedev.stackexchange.com/questions/32681/random-number-hlsl
// http://www.reedbeta.com/blog/2013/01/12/quick-and-easy-gpu-random-numbers-in-d3d11/
// https://docs.unity3d.com/Manual/RenderDocIntegration.html
// https://docs.unity3d.com/Manual/SL-ShaderPrograms.html

Shader "Unlit/SingleColor"
{
    SubShader
    {
        Pass
        {

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
	
		
	float rand(in float2 uv, in float seed)
	{
		float2 noise = (frac(sin(dot(uv+seed, float2(12.9898, 78.233)*2.0)) * 43758.5453));
		return abs(noise.x + noise.y) * 0.5;
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

	vec3 PointAt(Ray ray, float t)
	{
	    return ray.origin + t * ray.direction;
	}

////////////////////////////////////////////////////////////////////////////////////////////////////////

		struct Camera
	{
		
		vec3 lower_left_corner;
		vec3 horizontal;
		vec3 vertical;
		vec3 origin;
		
	};

		Camera MakeCamera()
		{
			Camera c;
			
			c.lower_left_corner = vec3(-2, -1, -1);
			c.horizontal = vec3(4, 0, 0);
			c.vertical = vec3(0, 2, 0);
			c.origin = vec3(0, 0, 0);

			return c;
		}

		Ray getCameraRay(Camera c,float x,float y)
		{
			return MakeRay(c.origin, c.lower_left_corner + x*c.horizontal + y*c.vertical);
		}
		
		
///////////////////////////////////////////////////////////////////////////////////////////////////////////
	
		struct Hit_record
        {
        	vec3 position;
        	vec3 normal;
        	float t;
			bool front_face;
        };

		void set_face_normal(Ray r, vec3 outward_normal, Hit_record h)
		{
			h.front_face = dot(r.direction, outward_normal) < 0;
			h.normal = h.front_face ? outward_normal : -outward_normal;
		}
////////////////////////////////////////////////////////////////////////////////////////////////////////

		struct Sphere
		{
			vec3 center;
			float radius;
		};

		Sphere makeSphere(vec3 center, float radius)
		{
			Sphere s;
			s.center = center;
			s.radius = radius;

			return s;
		}

		bool hit_sphere(float t_min, float t_max, Sphere s,Ray r, out Hit_record record)
        	{
			//midlertigie verdier 
			record.t = 0.0;
			record.position = vec3(0, 0, 0);
			record.normal = vec3(0, 0, 0);
			set_face_normal(r, record.normal, record);
			record.front_face = false;
			
        		vec3 oc = s.center - r.origin;
        		float a = dot(r.direction, r.direction);
        		float h = dot(r.direction, oc);
        		float c = dot(oc, oc) - s.radius * s.radius;
			
        		float discriminant = h * h - a * c;
        
        		if (discriminant < 0)
        		{
            		return false;
        		}

				float sqrtd = sqrt(discriminant);

				//find the nearest root that lies in the acceptable range. 
				float root = (h - sqrtd) / a;
			
        		if (root <= t_min || t_max <= root)
        		{
        			root = (h + sqrtd) / a;
        			if (root <= t_min || t_max <= root)
        			{
        				return false;
        			}
        		}

			record.t = root;
			vec3 p = PointAt(r,record.t);
			record.position = p;
			record.normal = (record.position - s.center) / s.radius;

			return true;
        	}
////////////////////////////////////////////////////////////////////////////////////////////////////////
		static const uint NUMBER_OF_SPHERES = 2;
		static const Sphere WORLD[NUMBER_OF_SPHERES] = {
			{ vec3(0.0, 0.0, -1.0), 0.5 },
			{ vec3(0.0, -100.5, -1.0), 100.0 }
		};

		
		col3 background(Ray ray)
		{
			float a = 0.5*((ray.direction).y+1.0);
			col3 col = (1.0 - a)*col3(1.0,1.0,1.0)+a*col3(0.5,0.7,1.0);
			return col;
		}


		
		col3 beginTracing(Ray ray)
		{
			Hit_record record;
			bool hit_anything = false;
			float closest_t = 10000.0;
			
			for (uint i = 0; i < NUMBER_OF_SPHERES; i++) {
				Hit_record temp_record;
                if (hit_sphere(0.001,closest_t, WORLD[i], ray, temp_record)){
                	hit_anything = true;
                	closest_t = temp_record.t;
                	record = temp_record;
                }
			}
			
			if (hit_anything)
			{
				vec3 N = record.normal;
				return col3(0.5*col3(N.x+1, N.y+1, N.z+1));
			}
			  return background(ray);
		}
		

	


////////////////////////////////////////////////////////////////////////////////////////////////////////
		
		
		
	fixed4 frag(v2f i) : SV_Target
	{
		int sampleNumber = 100;
		
		float x = i.uv.x;
		float y = i.uv.y;

		float2 xy = i.uv;

		Camera c = MakeCamera();
		col3 col = col3(0.0, 0.0, 0.0);

		for (int i = 0; i < sampleNumber; i++)
		{
			float seed = i * 100;
			float dx = (rand(xy, seed) - 0.5) * (4.0 / _ScreenParams.x);
			float dy = (rand(xy, seed + 1.5) - 0.5) * (2.0 / _ScreenParams.y);

			Ray ray = getCameraRay(c,x+dx,y+dy);
			col += beginTracing(ray);
		}

		col = col / sampleNumber;
		return fixed4(col,1); 
	}

	
////////////////////////////////////////////////////////////////////////////////////


ENDCG

        }
    }
}