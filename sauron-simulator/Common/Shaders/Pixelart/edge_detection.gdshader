shader_type spatial;
render_mode  ambient_light_disabled, specular_disabled, fog_disabled;

uniform sampler2D DEPTH_TEXTURE : hint_depth_texture, filter_linear_mipmap;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_nearest;
uniform sampler2D NORMAL_TEXTURE : hint_normal_roughness_texture, filter_nearest;

uniform float lightIntensity = 1.25;
uniform float lineAlpha = 0.7;
uniform bool useLighting = true;
uniform float lineHighlight = 0.2;
uniform float lineShadow = 0.55;
uniform vec4 outline_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float depth_threshold = 0.05;
uniform float normal_threshold = 0.5;

varying vec2 screenUV;
varying float lineMask;




float GetLinearDepth(vec2 sUV, sampler2D depthTexture, mat4 invProjectionMat, float mask){
	// Raw depth to linear depth code from:
	// https://docs.godotengine.org/en/latest/tutorials/shaders/advanced_postprocessing.html
	float depth = texture(depthTexture, sUV).x * mask;
	vec3 ndc = vec3(sUV * 2.0 - 1.0, depth);
    vec4 view = invProjectionMat * vec4(ndc, 1.0);
	view.xyz /= view.w;
	return -view.z;
}

vec3 GetNormal(vec2 uv, sampler2D normalTexture, float mask){
	vec3 normal = texture(normalTexture, uv).rgb;
	normal = normal * 2.0 - 1.0 * mask;
	return normal;
}

float NormalEdgeIndicator(vec3 normalEdgeBias, vec3 normal, vec3 neighborNormal, float depthDifference){
	//From Kody King: https://threejs.org/examples/webgl_postprocessing_pixel.html
	float normalDifference = dot(normal - neighborNormal, normalEdgeBias);
	float normalIndicator = clamp(smoothstep(-.01, .01, normalDifference), 0.0, 1.0);
	float depthIndicator = clamp(sign(depthDifference * .5 + .005), 0.0, 1.0);
	return (1.0 - dot(normal, neighborNormal)) * depthIndicator * normalIndicator;
}

void vertex(){
  POSITION = vec4(VERTEX.xy, 1.0, 1.0);
}

void fragment() {
	vec2 texelSize = (1.0 / VIEWPORT_SIZE.xy);
    vec3 screen_color = texture(SCREEN_TEXTURE, SCREEN_UV).rgb;
    
    float outlineMask = ceil(texture(NORMAL_TEXTURE, SCREEN_UV).a);

    // Optimized 4-tap sampling
    float d = GetLinearDepth(SCREEN_UV, DEPTH_TEXTURE, INV_PROJECTION_MATRIX, 1.0);
    vec3 n = GetNormal(SCREEN_UV, NORMAL_TEXTURE, 1.0);
    
    float edge = 0.0;
    
    // Sample neighbors
    vec2 offsets[4] = { vec2(0,1), vec2(0,-1), vec2(1,0), vec2(-1,0) };
    
    for(int i = 0; i < 4; i++) {
        vec2 neighbor_uv = SCREEN_UV + offsets[i] * texelSize;
        
        // Depth Edge
        float dn = GetLinearDepth(neighbor_uv, DEPTH_TEXTURE, INV_PROJECTION_MATRIX, 1.0);
        float d_diff = abs(d - dn);
        edge += step(depth_threshold, d_diff);
        
        // Normal Edge
        vec3 nn = GetNormal(neighbor_uv, NORMAL_TEXTURE, 1.0);
        float n_diff = 1.0 - dot(n, nn);
        edge += step(normal_threshold, n_diff);
    }
    
    edge = clamp(edge * outlineMask, 0.0, 1.0);
    
    // Mix the original screen with the outline color based on the edge strength
    vec3 final_color = mix(screen_color, outline_color.rgb, edge * lineAlpha);
    ALBEDO = final_color;
}

void light (){
	if (useLighting){
		vec4 normal = texture(NORMAL_TEXTURE, screenUV);
		normal = normal * 2.0 - 1.0;

		// Calculate light direction
		float dotNL = dot(normal.rgb, LIGHT);
		dotNL = pow(dotNL, 2.5);
		dotNL = clamp(dotNL, 0.0, 1.0);


		DIFFUSE_LIGHT += mix(vec3(1.0), dotNL * LIGHT_COLOR * lightIntensity , lineMask)* ATTENUATION;
		//DIFFUSE_LIGHT += clamp(dot(NORMAL, LIGHT), 0.0, 1.0) * ATTENUATION * LIGHT_COLOR / PI;
	}
	else
		DIFFUSE_LIGHT = vec3(1.0);
}
