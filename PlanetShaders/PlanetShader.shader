shader_type canvas_item;
render_mode blend_mix;

uniform float axisTilt : hint_range(0.0, 6.28) = 0.0;
uniform vec2 lightOrigin = vec2(0.0, 0.5);
uniform float timeSpeed : hint_range(0.0, 1.0) = 0.2;

uniform vec4 starLight : hint_color;
uniform float starIntensity: hint_range( 0.0 , 5.0 ) = 1.0;

uniform bool hasCraters = true;
uniform float craterDepth : hint_range( 0.25 , 0.75 ) = 0.25;
uniform int craterDensity : hint_range( 1 , 50.0 ) = 1;
uniform float mountainDensity : hint_range( 0.0 , 0.75 ) = 0.25;

uniform bool hasHydrosphere = true;
uniform vec4 riverCol : hint_color;
uniform float riverHeight : hint_range( 0.0 , 2.0 ) = 1.0;
uniform float riverCutoff : hint_range(0.0, 1.0) = 1.0;
uniform float riverAbsorption : hint_range( 0.0 , 0.5 ) = 1.0;
uniform float riverRoughness: hint_range( 0.0 , 1.0 ) = 0.0;
uniform vec4 riverRoughnessColor : hint_color = vec4( 1 , 1 ,1 ,1 );

uniform vec4 iceCapCol : hint_color;
uniform float iceCapThreshold :  hint_range( 0.0 , 0.5 ) = 0.0;
uniform float iceCapAbsorption: hint_range( 0.0 , 0.5 ) = 0.0;
uniform float iceCapRoughness : hint_range( 0.0 , 1.0 ) = 0.0;

uniform sampler2D gradient;


uniform bool isMap = false;

uniform float size = 4.0;
uniform float seed: hint_range( 1, 10 , .000000001 ) = 3.0;

float rand(vec2 coord) {
	// land has to be tiled (or the contintents on this planet have to be changing very fast)
	// tiling only works for integer values, thus the rounding
	// it would probably be better to only allow integer sizes
	// multiply by vec2(2,1) to simulate planet having another side
	coord = mod(coord, vec2(2.0,1.0)*round(size));
	return fract(sin(dot(coord.xy ,vec2(12.9898,78.233))) * 15.5453 * seed);
}

vec2 rand_vec_2( vec2 coord ) {
	// prevents randomness decreasing from coordinates too large
	coord = mod(coord, 10000.0);
	// returns "random" vec2 with x and y between 0 and 1
    return fract(sin( vec2( dot(coord,vec2(127.1,311.7) * seed), dot(coord,vec2(269.5,183.3) * seed) ) ) * 43758.5453 );
}


float noise(vec2 coord){
	vec2 i = floor(coord);
	vec2 f = fract(coord);
		
	float a = rand(i);
	float b = rand(i + vec2(1.0, 0.0));
	float c = rand(i + vec2(0.0, 1.0));
	float d = rand(i + vec2(1.0, 1.0));

	vec2 cubic = f * f * (3.0 - 2.0 * f);

	return mix(a, b, cubic.x) + (c - a) * cubic.y * (1.0 - cubic.x) + (d - b) * cubic.x * cubic.y;
}

vec4 mod289(vec4 x) {
    return x - floor(x * (1.0 / 289.0)) * 289.0;
}

vec4 taylorInvSqrt(vec4 r) {
    return 1.79284291400159 - 0.85373472095314 * r;
}

vec2 fade(vec2 t) {
    return t * t * t * (t * (t * 6.0 - 15.0) + 10.0);
}

vec4 permute(vec4 x) {
    return mod289(((x * 34.0) + 1.0) * x);
}

vec2 hash( float n )
{
    float sn = sin(n);
    return fract( vec2( sn , sn * 42125.13 * seed ) );
}

// by Leukbaars from https://www.shadertoy.com/view/4tK3zR
float circleNoise(vec2 uv ) {
   // float uv_y = uv.y;
   // uv.x += uv_y*.20;
   // vec2 f = fract(uv);
	//float h = rand(vec2(ceil(uv.x),floor(uv_y)));
    //float m = (length(f + 0.0 -( h * 0.5 ) ) );
    //float r = h*0.25;
    //return m = smoothstep(r - .01 * r - m, r + m, m);
	float uv_y = floor(uv.y);
    uv.x += uv_y * 0.31;
    vec2 f = fract(uv);
    vec2 h = hash(floor(uv.x) * uv_y);
    float m = (length(f - 0.25 - (h.x * 0.5 ) ) ) * 1.0;
    float r = h.y * .25;
    return m = smoothstep(r - 0.75 * r, r , m );
}

float mediumCrater( vec2 uv ){
	float c = 3.5;
	for (int i = 0; i < craterDensity; i++) {
		c *= circleNoise( ( uv + float(i) ) * 0.3 + float(i) );
	}
	c = 0.5 - c;
	return smoothstep( -1.0 , 1.0 ,  c );
}

float bigCrater(vec2 uv ) {
	float c = 3.5;
	for (int i = 0; i < craterDensity; i++) {
		c *= circleNoise( ( uv + float(i) ) * 0.1 + float(i) );
	}
	c = 0.5 - c;
	return smoothstep( -1.0 , 1.0 ,  c );
}


float vornoi_noise( vec2 coord ){
	vec2 i = floor( coord );
	vec2 f = fract( coord );
	
	// Check the space around the chosen coordinate
	// Note this will check inside 9 squares
	
	// setting  huge minimum value
	float minDist = 20.0;
	for( float x = -1.0; x <= 1.0; x++){
		for( float y = -1.0; y <= 1.0; y++){
			// Generate a random point within that square.
			vec2 node = rand_vec_2( i + vec2( x, y )) + vec2(x , y );		
			// Now we get the distance between that point and the current point
			float dist = sqrt((f - node).x * (f - node).x + (f - node).y * (f - node).y );
			minDist = min( minDist, dist );
		}
	}
	return minDist;
}

float fbm(vec2 coord){
	float value = 0.0;
	float scale = 0.5;

	float normalize_factor = 0.0;

	for(int i = 0; i < 4; i++){
		normalize_factor += scale;
		
		value += noise(coord) * scale;
		coord *= 2.0;
		scale *= 0.5;
	}
	return value / normalize_factor;
}

float landFbm( vec2 coord ){
	float value = 0.0;
	float scale = 0.6;
	float normalizeFactor = 0.0;
	
	for(int i = 1; i < 8; i++){
		normalizeFactor += scale;
		
		value += noise( coord ) * scale;
		coord *= 2.0;
		scale *= 0.5;
	}
	
	return value / normalizeFactor ;
}

vec2 spherify(vec2 uv) {
	vec2 centered = uv *2.0-1.0;
	float z = sqrt(1.0 - dot(centered.xy, centered.xy));
	vec2 sphere = centered/(z + 1.0);
	
	return sphere * 0.5+0.5;
}

vec2 rotate(vec2 coord, float angle){
	coord -= 0.5;
	coord *= mat2(vec2(cos(angle),-sin(angle)),vec2(sin(angle),cos(angle)));
	return coord + 0.5;
}

void fragment() {
	vec2 ogUV = UV;
	vec2 iceUV = UV;
	
	// Get light distance
	float d_light = 0.0;
	float a = 0.0;
	
	if( !isMap ){
		// Calculte directional light
		d_light = distance(ogUV , lightOrigin);
		d_light = pow(d_light, 2.0)*0.8;
		
		a = step(distance(vec2(0.5), ogUV), 0.496 ); // Cut available area into a circle. Cutting a bit more than 0.5 to deal with a light artifact.
		ogUV = spherify(ogUV); // Spherefy the UVs to give illusion of depth.
		ogUV = rotate(ogUV, axisTilt); // Rotate UVs
	} else {
		a = 1.0;
	}
	
	// Scroll by time if not a map. otherwise do nothing.
	vec2 uv = ogUV;
	if( isMap )
		uv = uv * size + vec2( uv.x * 2.0 , 0.0 );
	else
		uv = uv * size + vec2( TIME * timeSpeed , 0.0 );
	
	// Roll craters
	float craterRoll = 0.0;
	if( hasCraters )
		craterRoll = mediumCrater(uv) + bigCrater(uv);
		craterRoll = smoothstep( 0.0 , 0.95 , craterRoll );
	
	// Roll any noise up front so I can reuse it.
	float landNoise = landFbm( uv * 4.0 ) * 0.35; // LandNoise is meant to push numbers into reasonable ranges.
	float craterNoise = noise( uv * 2.0 + vornoi_noise( uv * 2.0 ) ) * 0.15; // This noise is used inside craters themselves to give them distinct texture
	float baseElevation = landFbm( uv * 1.0 + landFbm( uv * 4.0 ) ); // This is the basic elevation
	
	float hillFbm = baseElevation - ( craterRoll * craterDepth ) + mountainDensity - landNoise; // Final Elevation
	

	
	hillFbm = smoothstep( 0.05 , 0.95 , hillFbm );
	// mix a tiny bit of starLight into the entire image. This causes a subtle tracing effect around some features. Giving an illusion of depth.
	
	if( hillFbm <= 0.05 ){
		hillFbm += landNoise;
	}
	
	if( hillFbm >= 0.95 ){
		hillFbm -= landNoise;
	}
	hillFbm = smoothstep( 0.0 , 1.0 , hillFbm );
	vec3 col  = texture( gradient , vec2( hillFbm, 0.0 ) ).rgb;
	
	col = mix( col , starLight.rgb , (craterRoll + hillFbm + craterNoise - landNoise) * 0.1 );
	
	float iceCapY = 0.0;
	// Calculate water if it exists
	if( hasHydrosphere ){
		float riverFbm = landFbm( uv * 1.0 - landFbm( uv * 4.0 ) );
		if ( hillFbm <= 0.55 && riverFbm > 0.85 - riverCutoff && hillFbm <= riverCutoff ) {
			col = mix( col , riverCol.rgb , riverHeight );
			col = mix( col  , riverRoughnessColor.rgb  , riverFbm * riverRoughness );
			
			if( !isMap ){// # Add some star shading, but cap it so everything is still mostly the element color
				col = mix( starLight.rgb * starIntensity , col ,  smoothstep( 0.0 , 1.0 , d_light + ( riverAbsorption ) ) );
			}
				
		}
		
		float iceCapFbm = riverFbm * 0.18;

		if( hillFbm <= 0.75 && ( ogUV.y > 1.0 - (iceCapThreshold + iceCapFbm) || ogUV.y < iceCapThreshold + iceCapFbm ) ){
			col = mix( iceCapCol.rgb , iceCapCol.rgb + riverFbm , iceCapRoughness * riverFbm );
			if( !isMap )// # Add some star shading, but cap it so everything is still mostly the element color
				col = mix( starLight.rgb * starIntensity + hillFbm , col.rgb , smoothstep( 0.0 , 1.0 , d_light + ( iceCapAbsorption ) ) );
		}
	}
	
	// Trim the top & bottom to avoid weird artifacts.
	if( isMap ){
		if( ogUV.y > 0.9 || ogUV.y < 0.1 )
			a = 0.0;
	} else {
		// Light borders should shift a bit based on how 'high' the terrain is.
		float lightHeight = hillFbm * 0.4;
		//clamp( 0.0 , 0.85  , d_light  + lightHeight )* 2.0 + lightHeight)  
		col = mix( col , vec3( 0, 0, 0 ), smoothstep( 0.0 , 1.0 ,  ( d_light - lightHeight ) ) / 1.0 );
		col = mix( ( starLight.rgb + starLight.rgb * starIntensity ) / 2.0 + hillFbm ,  col , smoothstep( 0.0 , 0.8 , d_light + ( lightHeight ) ) );
	}
	
	COLOR = vec4( col , a );
	// COLOR = vec4( iceCapY, d_light , 1 , a );
}
