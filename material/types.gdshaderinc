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