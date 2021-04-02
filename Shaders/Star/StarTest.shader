shader_type canvas_item;

uniform vec4 color1 : hint_color = vec4( 0.8, 0.65, 0.3 , 1 );
uniform vec4 color2 : hint_color = vec4( 0.8, 0.35, 0.1 , 1 );

// If numbers get super big, you'll get banding. Best to keep coordinates very small for use of this function.
float rand(vec2 coord){
	// prevents randomness decreasing from coordinates too large
	coord = mod( coord, 10000.0 );
		// returns "random" vec2 with x and y between 0 and 1
	return fract(sin(dot(coord, vec2(12.9898, 78.233))) * 43758.5453);
}

vec2 rand_vec_2( vec2 coord ) {
	// prevents randomness decreasing from coordinates too large
	coord = mod(coord, 10000.0);
	// returns "random" vec2 with x and y between 0 and 1
    return fract(sin( vec2( dot(coord,vec2(127.1,311.7)), dot(coord,vec2(269.5,183.3)) ) ) * 43758.5453);
}


float snoise(vec3 uv, float res)
{
	const vec3 s = vec3(1e0, 1e2, 1e3);
	
	uv *= res;
	
	vec3 uv0 = floor(mod(uv, res))*s;
	vec3 uv1 = floor(mod(uv+vec3(1.), res))*s;
	
	vec3 f = fract(uv); f = f*f*(3.0-2.0*f);

	vec4 v = vec4(uv0.x+uv0.y+uv0.z, uv1.x+uv0.y+uv0.z,
		      	  uv0.x+uv1.y+uv0.z, uv1.x+uv1.y+uv0.z);

	vec4 r = fract(sin(v*1e-1)*1e3);
	float r0 = mix(mix(r.x, r.y, f.x), mix(r.z, r.w, f.x), f.y);
	
	r = fract(sin((v + uv1.z - uv0.z)*1e-1)*1e3);
	float r1 = mix(mix(r.x, r.y, f.x), mix(r.z, r.w, f.x), f.y);
	
	return mix(r0, r1, f.z)*2.-1.;
}

float vornoi_noise( vec2 coord ){
	vec2 i = floor( coord );
	vec2 f = fract( coord );
	
	// Check the space around the chosen coordinate
	// Note this will check inside 9 squares
	
	// setting  huge minimum value
	float minDist = 9999.0;
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

float fbm( vec2 coord ){
	int OCTAVES = 6;
	
	float normalize_factor = 0.0;
	float value = 0.0;
	float scale = 0.6;
	
	for(int i = 0; i < OCTAVES; i++){
		
		normalize_factor += scale;
		value += vornoi_noise( coord ) * scale;

		coord *= 2.0;
		scale *= 0.6;
	}
	
	return value / normalize_factor;
}

void fragment(){
	
	float myWorley = fbm( UV );
	
	float freqs1 = 0.01;
	float freqs2 = 0.07;
	vec2 uv = UV * 1.0;
	
	float brightness	= freqs1 * 0.25 + freqs2 * 0.25;
	float radius		= 0.24 + brightness * 1.0;
	float invRadius 	= 1.0/radius;

	float time		= TIME * 0.1;
	vec2 p = -0.5 + uv;
	float fade		= pow( length( 2.0 * p ), 0.5 );
	float fVal1		= 1.0 - fade;
	float fVal2		= 1.0 - fade;
	
	float angle		= atan( p.x, p.y )/6.2832;
	float dist		= length(p);
	vec3 coord		= vec3( angle, dist, time * 0.1 );
	
	float newTime1	= abs( snoise( coord + vec3( 0.0, -time * ( 0.35 + brightness * 0.001 ), time * 0.115 ), 15.0 ) );
	float newTime2	= abs( snoise( coord + vec3( 0.0, -time * ( 0.15 + brightness * 0.001 ), time * -0.115 ), 45.0 ) );	
	for( int i=1; i<=4; i++ ){
		float power = pow( 3.0, float(i + 1) );
		fVal1 += ( 0.5 / power ) * snoise( coord + vec3( 0.0, -time, time * 0.01 ), ( power * ( 10.0 ) * ( newTime1 + 1.0 ) ) );
		fVal2 += ( 0.5 / power ) * snoise( coord + vec3( 0.0, -time, time * 0.01 ), ( power * ( 25.0 ) * ( newTime2 + 1.0 ) ) );
	}
	
	float corona		= pow( fVal1 * max( 1.1 - fade, 0.0 ), 2.0 ) * 50.0;
	corona				+= pow( fVal2 * max( 1.1 - fade, 0.0 ), 2.0 ) * 50.0;
	corona				*= 1.2 - newTime1;
	
	vec3 sphereNormal 	= vec3( 0.0, 0.0, 1.0 );
	vec3 dir 			= vec3( 0.0 );
	vec3 center			= vec3( 0.5, 0.5, 1.0 );
	vec3 starSphere		= vec3( 0.0 );
	
	vec2 sp = -1.0 + 2.0 * uv;
	sp *= ( 2.0 - brightness );
	
  	float r = dot(sp,sp);
	float f = (1.0-sqrt(abs(1.0-r)))/(r) + brightness * 0.5;
	
	if( dist < radius ){
		// Controls how far the corona effect extends. Tweaked to allow Corona onto star surface and give it some depth.
		corona *= pow( dist * invRadius, 10.0 );
		
		vec2 newUv;
		newUv.x = sp.x*f;
		newUv.y = sp.y*f;
		
		float offset = time;
		
		newUv += vec2( offset , 0.0 );
		vec2 starUV	= newUv + vec2( offset, 0.0 );
		starSphere	= color2.rgb * fbm( starUV ) * 6.0;
	}
	
	float starGlow	= max( 1.0 + dist * ( 1.0 - brightness ), 0.0 );
	vec3 color = vec3( f * ( 0.75 + brightness * 0.7 ) * color1.rgb ) + starSphere + corona * color1.rgb * color2.rgb * starGlow;
	
	COLOR = vec4( color , 1 );
	// COLOR = vec4( myWorley * 0.1 , 1 , 1, 1 );
}
