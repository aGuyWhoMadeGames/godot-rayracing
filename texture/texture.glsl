#[compute]
#version 450

// Invocations in the (x, y, z) dimension
layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

layout(rgba8, set = 0, binding = 0) uniform restrict writeonly image2D output_image;

layout(push_constant, std430) uniform Params {
	mat3 camBasis;
	vec3 camPos;
	mat4 invProjection;
} params;

const float PI = 3.1415;

struct Ray
{
	vec3 origin;
	vec3 dir;
};

struct RayTracingMaterial
{
	vec4 colour;
	vec4 emissionColour;
	vec4 specularColour;
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
				state = state * 747796405 + 2891336453;
				uint result = ((state >> ((state >> 28) + 4)) ^ state) * 277803737;
				result = (result >> 22) ^ result;
				return result;
			}

			float RandomValue(inout uint state)
			{
				return NextRandom(state) / 4294967295.0; // 2^32 - 1
			}

			// Random value in normal distribution (with mean=0 and sd=1)
			float RandomValueNormalDistribution(inout uint state)
			{
				// Thanks to https://stackoverflow.com/a/6178290
				float theta = 2 * 3.1415926 * RandomValue(state);
				float rho = sqrt(-2 * log(RandomValue(state)));
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
				float angle = RandomValue(rngState) * 2 * PI;
				vec2 pointOnCircle = vec2(cos(angle), sin(angle));
				return pointOnCircle * sqrt(RandomValue(rngState));
			}


HitInfo RaySphere(Ray ray, vec3 sphereCentre, float sphereRadius)
{
	HitInfo hitInfo;
	hitInfo.didHit = false;
	
	vec3 offsetRayOrigin = ray.origin - sphereCentre;
	// From the equation: sqrLength(rayOrigin + rayDir * dst) = radius^2
	// Solving for dst results in a quadratic equation with coefficients:
	float a = dot(ray.dir, ray.dir); // a = 1 (assuming unit vector)
	float b = 2 * dot(offsetRayOrigin, ray.dir);
	float c = dot(offsetRayOrigin, offsetRayOrigin) - sphereRadius * sphereRadius;
	// Quadratic discriminant
	float discriminant = b * b - 4 * a * c; 

	// No solution when d < 0 (ray misses sphere)
	if (discriminant >= 0) {
		// Distance to nearest intersection point (from quadratic formula)
		float dst = (-b - sqrt(discriminant)) / (2 * a);

		// Ignore intersections that occur behind the ray
		if (dst >= 0) {
			hitInfo.didHit = true;
			hitInfo.dst = dst;
			hitInfo.hitPoint = ray.origin + ray.dir * dst;
			hitInfo.normal = normalize(hitInfo.hitPoint - sphereCentre);
		}
	}
	return hitInfo;
}

HitInfo CalculateRayCollision(Ray ray)
{
	HitInfo closestHit;
	
	HitInfo hitInfo = RaySphere(ray,vec3(0.0),1.0);
	closestHit = hitInfo;
	closestHit.material.colour = vec4(1.0,0.0,0.0,1.0);
	
	return hitInfo;
}

void main() {
	ivec2 uvi = ivec2(gl_GlobalInvocationID.xy);
	vec2 uv = uvi/512.0;
	uv.y = -uv.y;
	
	Ray ray;
	
	ray.origin = params.camPos;
	ray.dir = params.camBasis*normalize((params.invProjection*vec4(uv-0.5,0.0,1.0)).xyz);
	//ray.dir = params.camBasis*vec3(uv-0.5,1.0);
	
	HitInfo hit = CalculateRayCollision(ray);
	
	imageStore(output_image, uvi, vec4(vec3(hit.didHit),1.0));
}
