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
		
	static float seed = 0.0;


		float rand(in float2 uv)
	{
		float2 noise = (frac(sin(dot(uv, float2(12.9898, 78.233)*2.0)) * 43758.5453));
		return abs(noise.x + noise.y) * 0.5;
	}

		float random_float(float2 xy)
		{
			float2 uv = float2(xy.x + seed, xy.y + seed);
			float random = rand(uv);
			seed += 0.1;
			return random;
		}
		
	vec3 random_unit_vector(float2 xy)
	{
		vec3 p;
			do {
				
				p = 2.0 * vec3(random_float(xy), random_float(xy), random_float(xy))- vec3(1.0, 1.0, 1.0);
			} while (dot(p, p) >= 1.0);
		return p;
	}


		vec3 random_on_hemisphere(vec3 normal, float2 xy)
		{
			vec3 on_unit_sphere = random_unit_vector(xy);
			if (dot(on_unit_sphere, normal) > 0.0)
			{
				return on_unit_sphere;
			}else
			{
				return -on_unit_sphere;
			}
		}
		
		
		vec3 unit_vector(vec3 v){
			return v / sqrt(dot(v,v));
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
			c.origin = vec3(0,0,0);

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
			col3 albedo;
			float fuzz;
			bool isMetal;
			bool isDielectric;
			float refraction_index;
        };

		void set_face_normal(Ray r, inout vec3 outward_normal, inout Hit_record h)
		{
			h.front_face = dot(r.direction, outward_normal) < 0;
			h.normal = h.front_face ? outward_normal : -outward_normal;
		}
////////////////////////////////////////////////////////////////////////////////////////////////////////

		struct Sphere
		{
			vec3 center;
			float radius;
			col3 albedo;
			float fuzz;
			bool isMetal;
			bool isDielectric;
			float refraction_index;
		};

		Sphere makeSphere(vec3 center, float radius, col3 albedo, float fuzz, bool isMetal, bool isDielectric, float refraction_index)
		{
			Sphere s;
			s.center = center;
			s.radius = radius;
			s.albedo = albedo;
			s.fuzz = fuzz;
			s.isMetal = isMetal;
			s.isDielectric = isDielectric;
			s.refraction_index = refraction_index;
			
			return s;
		}

		bool hit_sphere(float t_min, float t_max, Sphere s,Ray r, out Hit_record record)
        	{
			//midlertigie verdier 
			record.position = vec3(0, 0, 0);
			record.normal = vec3(0, 0, 0);
			record.t = 0.0;
			record.front_face = false;
			record.albedo = col3(0,0,0);
			record.fuzz = 0.0;
			record.isMetal = false;
			record.isDielectric = false;
			record.refraction_index = 0.0;
			
			
			
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
			vec3 outward_normal = (record.position - s.center) / s.radius;
			set_face_normal(r,outward_normal,record);
			record.albedo = s.albedo;
			record.fuzz = s.fuzz;
			record.isMetal = s.isMetal;
			record.isDielectric = s.isDielectric;
			record.refraction_index = s.refraction_index;

			return true;
        	}
////////////////////////////////////////////////////////////////////////////////////////////////////////
		static const uint NUMBER_OF_SPHERES = 5;
		static const Sphere WORLD[NUMBER_OF_SPHERES] = {
			{ vec3(0.0, 0.0, -1.2), 0.5 , col3(0.1, 0.2, 0.5), 0.5,false,false, 0.0},
			{ vec3(0.0, -100.5, -1.0), 100.0 , col3(0.8, 0.8, 0.0), 0.0,false,false, 0.0},
			{ vec3(1.0, 0.0, -1.0), 0.5 , col3(0.8, 0.6, 0.2), 0.5,true,false, 0.0},
			{ vec3(-1.0, 0.0, -1.0), 0.5 , col3(1.0, 1.0, 1.0), 0.0,false,true, (1/1.5)},
			{ vec3(-1.0, 0.0, -1.0), 0 , col3(1.0, 1.0, 0), 0.0,true,true, (1.5)}
		};

		
		col3 background(Ray ray)
		{
			float a = 0.5*((ray.direction).y+1.0);
			col3 col = (1.0 - a)*col3(1.0,1.0,1.0)+a*col3(0.5,0.7,1.0);
			return col;
		}

		bool calculateSpheresIntersect(float t_min, float t_max,Ray r, out Hit_record record)
		{
			bool hit_anything = false;
			float closest_t = t_max;
			Hit_record temp_record;

			for (uint i = 0; i < NUMBER_OF_SPHERES; i++) {
                if (hit_sphere(0.001,closest_t, WORLD[i], r, temp_record)){
                	hit_anything = true;
                	closest_t = temp_record.t;
                	record = temp_record;
                }
			}

			return hit_anything;
		}

		bool near_zero(vec3 v)
		{
		    float s = 1e-8;
		    return (abs(v.x) < s) && (abs(v.y) < s) && (abs(v.z) < s);
		}
		
		vec3 reflect(vec3 v, vec3 n)
		{
			return (v-2*dot(v,n)*n);
		}

		float length_squared(vec3 v)
		{
			return dot(v, v);
		}


		vec3 refract(vec3 uv, vec3 n, float etai_over_etat)
		{
			float cos_theta = min(dot(-uv, n), 1.0);
			vec3 r_out_perp = etai_over_etat * (uv + (cos_theta*n));
			vec3 r_out_parallel = -sqrt(abs(1.0-length_squared(r_out_perp)))*n;
			return r_out_perp + r_out_parallel;
		}

		float reflectance(float cosine, float refraction_index)
		{
			float r0 = (1-refraction_index) / (1+refraction_index);
			r0 = r0 * r0;
			return r0 + (1-r0)*pow((1.0-cosine), 5);
		}
		

bool scatter(Ray ray, Hit_record record, out col3 attenuation, out Ray scattered, float2 xy)
		{
			
			if (record.isMetal)
			{
				vec3 reflected = reflect(ray.direction, record.normal);
				reflected = unit_vector(reflected) + (record.fuzz*random_unit_vector(xy));
				scattered = MakeRay(record.position, reflected  );
				attenuation = record.albedo;
				return (dot(scattered.direction, record.normal) > 0);
			}

			else if (record.isDielectric)
			{
				attenuation = col3(1.0,1.0,1.0);
				float ri = record.front_face ? (1.0/record.refraction_index) : record.refraction_index;

				vec3 unit_direction = unit_vector(ray.direction);
				
				float cos_theta = min(dot(-unit_direction, record.normal), 1.0);
				float sin_theta = sqrt(1.0-cos_theta*cos_theta);

				bool cannot_refract = ri * sin_theta > 1.0;
				vec3 direction;

				if (cannot_refract || reflectance(cos_theta, ri) > random_float(xy))
				{
					direction = reflect(unit_direction, record.normal);
				}else
				{
					direction = refract(unit_direction, record.normal, ri);
				}
				scattered = MakeRay(record.position, direction);
				
				return true;
			}
			else
			{
				vec3 direction = random_on_hemisphere(record.normal, xy);
                
                if (near_zero(direction))
                {
                	direction = record.normal;
                }
                
                scattered = MakeRay(record.position, direction);
                attenuation = record.albedo;
                return true;
			}
			
			
		}
		
		
		col3 beginTracing(Ray ray, float2 xy)
		{
			Hit_record record;
			col3 accumCol = {1,1,1};
			float closest_t = 10000.0;
			bool hit_anything = calculateSpheresIntersect(0.001,closest_t, ray, record);
			int maxC = 15;
			
			
            while (hit_anything && (maxC > 0) ){
                maxC--;

            	Ray scattered;
            	col3 attenuation;
                scatter(ray, record, attenuation, scattered, xy);
                
                vec3 direction = random_on_hemisphere(record.normal, xy);

               
				accumCol *= attenuation;
                
                hit_anything = calculateSpheresIntersect(0.001,closest_t, scattered, record);
            }

			if (hit_anything && maxC == 0)
			{
				return col3(0,0,0);
			}
			
			return accumCol * background(ray);
			  
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
			float dx = (random_float(xy)* (4 /_ScreenParams.x));
			float dy = (random_float(xy)*(2 /_ScreenParams.y));

			Ray ray = getCameraRay(c,x+dx,y+dy);
			col += beginTracing(ray, xy);
		}

		col = col / sampleNumber;

		col = sqrt(col); // Gamma
		
		return fixed4(col,1); 
	}

	
////////////////////////////////////////////////////////////////////////////////////


ENDCG

        }
    }
}