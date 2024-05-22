shader_type spatial;

render_mode unshaded, cull_disabled, skip_vertex_transform;

#include "res://level/level geometry.gdshaderinc"
#include "res://material/types.gdshaderinc"
#include "res://material/random.gdshaderinc"


uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear;

uniform mat4 prevView;

varying mat4 view_mat;
varying mat4 prev_view_mat;


vec3 Trace(Ray ray, inout uint rngState){
	vec3 incomingLight = vec3(0.0);
	vec3 rayColour = vec3(1.0);
	for(int i = 0;i<6;i++){
		HitInfo hit = CalculateRayCollision(ray);

		if(hit.didHit){
			//incomingLight += hit.material.colour.rgb * rayColour;
			ray.origin = hit.hitPoint;
			vec3 diffuseDir = normalize(hit.normal + RandomDirection(rngState));
			//vec3 diffuseDir = reflect(ray.dir,hit.normal);
			ray.dir = diffuseDir;
			incomingLight += hit.material.emissionColour*hit.material.emissionStrength*rayColour;
			rayColour *= hit.material.colour;
		} else{
			incomingLight += GetEnvironmentLight(ray) * rayColour;
			break;
		}
		/*if(dot(rayColour,rayColour)<0.0){
			break;
		}*/
	}
	return incomingLight;
}

void vertex() {
	view_mat = inverse(VIEW_MATRIX);
	prev_view_mat = inverse(prevView);
	POSITION = vec4(VERTEX.xy,1.0,1.0);
}

void fragment() {
	uint pixelIndex = uint(UV.x*VIEWPORT_SIZE.x*VIEWPORT_SIZE.y+UV.y*VIEWPORT_SIZE.x);
	uint rngState = pixelIndex * 31555131u + uint(TIME * 516152.0);

	Ray ray;
	
	
	vec4 pos = INV_PROJECTION_MATRIX*vec4(SCREEN_UV*2.0-1.0,1.0,1.0);
	vec3 vert = pos.xyz*pos.w;
	ray.origin = (view_mat*vec4(0,0,0,1)).xyz;
	ray.dir = normalize((view_mat * vec4(vert, 1.0)).xyz - ray.origin);
	//ray.dir = params.camBasis*vec3(uv-0.5,1.0);
	int samples = 4;

	vec3 color = vec3(0);
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
			
			ALBEDO = mix(prev,color/float(samples),offscreen?1.0:0.05);
			//ALBEDO = diff;
		} else{
			ALBEDO = color/float(samples);
			//ALBEDO = vec3(0.0);
		}
	} else{
		ALBEDO = color/float(samples);
	}
	DEPTH = 0.0;
}


