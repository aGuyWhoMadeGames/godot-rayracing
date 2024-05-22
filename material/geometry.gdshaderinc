#include "types.gdshaderinc"

void combine(inout HitInfo a, HitInfo b){
	if (b.didHit && b.dst < a.dst){
		a = b;
	}
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