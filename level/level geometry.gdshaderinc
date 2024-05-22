#include "res://material/types.gdshaderinc"
#include "res://material/geometry.gdshaderinc"

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

HitInfo CalculateRayCollision(Ray ray)
{
	HitInfo closestHit;
	closestHit.didHit = false;
	closestHit.dst = 1e6;

	HitInfo hitInfo;

	hitInfo = RayBox(ray,vec3(0,0,0),vec3(30,-1,7));
	hitInfo.material.colour = vec3(0.9);
	combine(closestHit,hitInfo);
	
	hitInfo = RayBox(ray,vec3(0,0,0),vec3(30,5,1));
	hitInfo.material.colour = vec3(0.9,0.5,0.5);
	combine(closestHit,hitInfo);
	
	hitInfo = RayBox(ray,vec3(0,0,6),vec3(30,5,7));
	hitInfo.material.colour = vec3(0.5,0.5,0.9);
	combine(closestHit,hitInfo);
	
	hitInfo = RayBox(ray,vec3(0,0,1),vec3(1,5,6));
	hitInfo.material.colour = vec3(0.5,0.9,0.5);
	combine(closestHit,hitInfo);
	
	hitInfo = RayBox(ray,vec3(30,0,1),vec3(29,5,6));
	hitInfo.material.colour = vec3(0.5,0.9,0.5);
	combine(closestHit,hitInfo);
	
	hitInfo = RayBox(ray,vec3(0,5,0),vec3(30,6,7));
	hitInfo.material.colour = vec3(0.9);
	combine(closestHit,hitInfo);
	
	hitInfo = RaySphere(ray,vec3(2.5,1,4.5),1.0);
	hitInfo.material.colour = vec3(0.9);
	combine(closestHit,hitInfo);
	
	hitInfo = RaySphere(ray,vec3(3.5,1,2.5),1.0);
	hitInfo.material.colour = vec3(0.9);
	combine(closestHit,hitInfo);
	
	hitInfo = RayBox(ray,vec3(2,4.5,2),vec3(5,5,5));
	hitInfo.material.colour = vec3(1);
	hitInfo.material.emissionColour = vec3(1);
	hitInfo.material.emissionStrength = 0.1;
	combine(closestHit,hitInfo);
	
	return closestHit;
}