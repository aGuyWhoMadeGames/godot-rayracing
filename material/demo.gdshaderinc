#include "types.gdshaderinc"
#include "geometry.gdshaderinc"

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