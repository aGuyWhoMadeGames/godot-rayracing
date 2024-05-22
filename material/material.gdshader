shader_type spatial;

render_mode unshaded, cull_disabled, depth_test_disabled, skip_vertex_transform;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear;

uniform mat4 prevView;

varying mat4 view_mat;
varying mat4 prev_view_mat;

struct Ray
{
	vec3 origin;
	vec3 dir;
};

struct RayTracingMaterial
{
	vec3 colour;
	vec3 emissionColour;
	vec3 specularColour;
	float emissionStrength;
	float smoothness;
	float specularProbability;
	int flag;
};

struct HitInfo
{
	bool didHit;
	float dst;
	vec3 hitPoint;
	vec3 normal;
	RayTracingMaterial material;
};

			uint NextRandom(inout uint state)
			{
				state = state * 747796405U + 2891336453U;
				uint result = ((state >> ((state >> 28U) + 4U)) ^ state) * 277803737U;
				result = (result >> 22U) ^ result;
				return result;
			}

			float RandomValue(inout uint state)
			{
				return float(NextRandom(state)) / 4294967295.0; // 2^32 - 1
			}

			// Random value in normal distribution (with mean=0 and sd=1)
			float RandomValueNormalDistribution(inout uint state)
			{
				// Thanks to https://stackoverflow.com/a/6178290
				float theta = 2.0 * 3.1415926 * RandomValue(state);
				float rho = sqrt(-2.0 * log(RandomValue(state)));
				return rho * cos(theta);
			}

			// Calculate a random direction
			vec3 RandomDirection(inout uint state)
			{
				// Thanks to https://math.stackexchange.com/a/1585996
				float x = RandomValueNormalDistribution(state);
				float y = RandomValueNormalDistribution(state);
				float z = RandomValueNormalDistribution(state);
				return normalize(vec3(x, y, z));
			}

			vec2 RandomPointInCircle(inout uint rngState)
			{
				float angle = RandomValue(rngState) * 2.0 * PI;
				vec2 pointOnCircle = vec2(cos(angle), sin(angle));
				return pointOnCircle * sqrt(RandomValue(rngState));
			}

			vec3 GetEnvironmentLight(Ray ray)
			{
				//return vec3(0.0);
				float skyGradientT = pow(smoothstep(0, 0.4, ray.dir.y), 0.35);
				float groundToSkyT = smoothstep(-0.01, 0, ray.dir.y);
				vec3 skyGradient = mix(vec3(0.1,0.1,0.5), vec3(0.1,0.1,0.5), skyGradientT);
				float sun = pow(max(0, dot(ray.dir, normalize(vec3(1.0)))), 25.0) * 2.0;
				// Combine ground, sky, and sun
				vec3 composite = mix(vec3(0.05), skyGradient, groundToSkyT) + sun * float(groundToSkyT>=1.0);
				return composite;
			}


HitInfo RaySphere(Ray ray, vec3 sphereCentre, float sphereRadius)
{
	HitInfo hitInfo;
	hitInfo.didHit = false;

	vec3 offsetRayOrigin = ray.origin - sphereCentre;
	// From the equation: sqrLength(rayOrigin + rayDir * dst) = radius^2
	// Solving for dst results in a quadratic equation with coefficients:
	float a = dot(ray.dir, ray.dir); // a = 1 (assuming unit vector)
	float b = 2.0 * dot(offsetRayOrigin, ray.dir);
	float c = dot(offsetRayOrigin, offsetRayOrigin) - sphereRadius * sphereRadius;
	// Quadratic discriminant
	float discriminant = b * b - 4.0 * a * c;

	// No solution when d < 0 (ray misses sphere)
	if (discriminant >= 0.0) {
		// Distance to nearest intersection point (from quadratic formula)
		float dst = (-b - sqrt(discriminant)) / (2.0 * a);

		// Ignore intersections that occur behind the ray
		if (dst >= 0.0) {
			hitInfo.didHit = true;
			hitInfo.dst = dst;
			hitInfo.hitPoint = ray.origin + ray.dir * dst;
			hitInfo.normal = normalize(hitInfo.hitPoint - sphereCentre);
		}
	}
	return hitInfo;
}

HitInfo RayBox(Ray ray, vec3 boxMin, vec3 boxMax)
{
	HitInfo hitInfo;
	vec3 invDir = 1.0 / ray.dir;
	vec3 tMin = (boxMin - ray.origin) * invDir;
	vec3 tMax = (boxMax - ray.origin) * invDir;
	vec3 t1 = min(tMin, tMax);
	vec3 t2 = max(tMin, tMax);
	float tNear = max(max(t1.x, t1.y), t1.z);
	float tFar = min(min(t2.x, t2.y), t2.z);
	if(tNear <= tFar && tNear > 0.0){
		hitInfo.didHit = true;
		hitInfo.dst = tNear;
		hitInfo.hitPoint = ray.origin + ray.dir * hitInfo.dst;
		
		vec3 localP = hitInfo.hitPoint - mix(boxMin,boxMax,0.5);
		vec3 normP = localP / abs(boxMax-boxMin);
		
		vec3 absP = abs(normP);
		float maxComp = max(max(absP.x,absP.y),absP.z);
		if(maxComp == absP.x){hitInfo.normal=vec3(sign(normP.x),0.0,0.0);}
		else if(maxComp == absP.y){hitInfo.normal=vec3(0.0,sign(normP.y),0.0);}
		else if(maxComp == absP.z){hitInfo.normal=vec3(0.0,0.0,sign(normP.z));}
		
	} else{
		hitInfo.didHit = false;
	}
	return hitInfo;
}


HitInfo CalculateRayCollision(Ray ray)
{
	HitInfo closestHit;
	closestHit.didHit = false;
	closestHit.dst = 1e6;

	HitInfo hitInfo;

	hitInfo = RaySphere(ray,vec3(0.0),1.0);
	if (hitInfo.didHit && hitInfo.dst < closestHit.dst){
		hitInfo.material.colour = vec3(0.9);
		//hitInfo.material.emissionColour = vec3(1.0);
		//hitInfo.material.emissionStrength = 0.3;
		closestHit = hitInfo;
	}
	

	hitInfo = RaySphere(ray,vec3(1.25,-0.75,0.0),0.5);
	if (hitInfo.didHit && hitInfo.dst < closestHit.dst){
		hitInfo.material.colour = vec3(1.0,0.5,0.5);
		closestHit = hitInfo;
		
	}

	hitInfo = RaySphere(ray,vec3(-1.0,-0.75,1.0),0.75);
	if (hitInfo.didHit && hitInfo.dst < closestHit.dst){
		hitInfo.material.colour = vec3(0.5,0.5,1.0);
		closestHit = hitInfo;
	}

	hitInfo = RaySphere(ray,vec3(0.0,-20.0,0.0),19.0);
	if (hitInfo.didHit && hitInfo.dst < closestHit.dst){
		hitInfo.material.colour = vec3(0.9);
		closestHit = hitInfo;
	}
	
	hitInfo = RayBox(ray,vec3(0.0,-1.0,2.0),vec3(5.0,-3.0,3.0));
	if (hitInfo.didHit && hitInfo.dst < closestHit.dst){
		hitInfo.material.colour = vec3(0.5);
		closestHit = hitInfo;
	}
	
	//hitInfo = RaySphere(ray,vec3(50.0),30.0);
	//if (hitInfo.didHit && hitInfo.dst < closestHit.dst){
		//hitInfo.material.colour = vec3(0.0);
		//hitInfo.material.emissionColour = vec3(1.0);
		//hitInfo.material.emissionStrength = 0.1;
		//closestHit = hitInfo;
	//}

	return closestHit;
}

vec3 Trace(Ray ray, inout uint rngState){
	vec3 incomingLight = vec3(0.0);
	vec3 rayColour = vec3(1.0);
	for(int i = 0;i<4;i++){
		HitInfo hit = CalculateRayCollision(ray);

		if(hit.didHit){
			//incomingLight += hit.material.colour.rgb * rayColour;
			ray.origin = hit.hitPoint;
			vec3 diffuseDir = normalize(hit.normal + RandomDirection(rngState));
			ray.dir = diffuseDir;
			//incomingLight += hit.material.emissionColour*hit.material.emissionStrength*rayColour;
			rayColour *= hit.material.colour;
		} else{
			incomingLight += GetEnvironmentLight(ray) * rayColour;
			break;
		}
		
	}
	return incomingLight;
}

void vertex() {
	view_mat = inverse(VIEW_MATRIX);
	prev_view_mat = inverse(prevView);
	POSITION = vec4(VERTEX.xy,1.0,1.0);
}

void fragment() {
	uint pixelIndex = uint(UV.x*10000000.0+UV.y*100000.0);
	uint rngState = pixelIndex + uint(TIME * 719393.0);

	Ray ray;
	
	
	vec4 pos = INV_PROJECTION_MATRIX*vec4(SCREEN_UV*2.0-1.0,1.0,1.0);
	vec3 vert = pos.xyz*pos.w;
	ray.origin = (view_mat*vec4(0,0,0,1)).xyz;
	ray.dir = normalize((view_mat * vec4(vert, 1.0)).xyz - ray.origin);
	//ray.dir = params.camBasis*vec3(uv-0.5,1.0);
	int samples = 48;

	vec3 color = vec3(0.0);
	for(int i=0;i<samples;i++){
		color += Trace(ray, rngState);
	}

	HitInfo hit = CalculateRayCollision(ray);
	
	if(hit.didHit){
		vec3 pos = hit.hitPoint;
		
		Ray prevRay;
		prevRay.origin = (prev_view_mat*vec4(0,0,0,1)).xyz;
		prevRay.dir = normalize(pos-prevRay.origin);
		HitInfo prevHit = CalculateRayCollision(prevRay);
		vec3 diff = pos-prevHit.hitPoint;
		
		if(dot(diff,diff)<0.0001&&prevHit.didHit){
			vec4 clipPos = (PROJECTION_MATRIX*prevView*vec4(pos,1.0));
			vec2 screenPos = clipPos.xy/clipPos.w;
			
			vec2 uv = screenPos*0.5+0.5;
			
			vec3 prev = texture(screen_texture,uv).rgb;
			
			bool offscreen = uv.x>1.0||uv.x<0.0 || uv.y>1.0||uv.y<0.0;
			
			ALBEDO = mix(prev,color/float(samples),offscreen?1.0:0.1);
			//ALBEDO = diff;
		} else{
			ALBEDO = color/float(samples);
			//ALBEDO = vec3(0.0);
		}
	} else{
		ALBEDO = color/float(samples);
	}

}
