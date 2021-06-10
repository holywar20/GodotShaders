shader_type canvas_item;

uniform float size = 8.0;
uniform float seed: hint_range(1, 10) = 5.0;

uniform float axisTilt : hint_range(0.0, 6.28) = 0.0;
uniform vec2 lightOrigin = vec2( 0.0 , 1 );
uniform float timeSpeed : hint_range(-1.0, 1.0) = 0.2;

uniform vec4 starLight : hint_color = vec4(1.0, 1.0, 1.0, 1.0 );
uniform float starIntensity : hint_range( 0.0 , 8.0 );
uniform vec4 fresnalColor : hint_color = vec4(0.0 , 0.11 , 1.0 , 1.0); // Blue 
uniform float fresnalRim : hint_range( 0.0 , 5.0 );

uniform float cloudCover : hint_range(0.0, 2.0) = 0.4;
uniform float stretch : hint_range( 2.0, 4.0 ) = 2.0;
uniform float cloudReflectence : hint_range( 0.01 , 1.0 );
uniform int turbulence : hint_range( 0 , 20 , 1 ) = 3;
uniform float mainCloudSpeed : hint_range( 0.0 , 20.0 ) = 2.0;

uniform sampler2D gradient;


float rand(vec2 coord) {
	coord = mod(coord, vec2(1.0,1.0)*round(size));
	return fract(sin(dot(coord.xy ,vec2(12.9898,78.233))) * 15.5453 * seed);
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

float fbm(vec2 coord){
	float value = 0.0;
	float scale = 0.5;

	for(int i = 0; i < 5 ; i++){
		value += noise(coord) * scale;
		coord *= 2.0;
		scale *= 0.5;
	}
	return value;
}

vec2 hash( float n )
{
    float sn = sin(n);
    return fract( vec2( sn , sn * 42125.13 * seed ) );
}

vec2 hash2( vec2 p ) {
	p = vec2(dot(p,vec2(127.1,311.7)), dot(p,vec2(269.5,183.3)));
	return -1.0 + 2.0*fract(sin(p)*43758.5453123);
}

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
    return m = smoothstep(r - 0.75 * r, r  , m );
}

vec2 spherify(vec2 uv) {
	vec2 centered= uv *2.0-1.0;
	float z = sqrt(1.0 - dot(centered.xy, centered.xy));
	vec2 sphere = centered/(z + 1.0);
	return sphere * 0.5+0.5;
}

float cloudNoise( in vec2 p ) {
    const float K1 = 0.366025404; // (sqrt(3)-1)/2;
    const float K2 = 0.211324865; // (3-sqrt(3))/6;
	vec2 i = floor(p + (p.x+p.y)*K1);	
    vec2 a = p - i + (i.x+i.y)*K2;
    vec2 o = (a.x>a.y) ? vec2(1.0,0.0) : vec2(0.0,1.0); //vec2 of = 0.5 + 0.5*vec2(sign(a.x-a.y), sign(a.y-a.x));
    vec2 b = a - o + K2;
	vec2 c = a - 1.0 + 2.0*K2;
    vec3 h = max(0.5-vec3(dot(a,a), dot(b,b), dot(c,c) ), 0.0 );
	vec3 n = h*h*h*h*vec3( dot(a,hash2(i+0.0)), dot(b,hash2(i+o)), dot(c,hash2(i+1.0)));
    return dot(n, vec3(70.0));	
}

float cloud_alpha(vec2 uv , float t) {
	float c_noise = 0.1;
	
	// more iterations for more turbulence
	if( turbulence > 0 ){
		for (int i = 0; i < turbulence; i++) {
			c_noise += circleNoise( ( uv * 0.1) + (float(i+1)+10.) + (vec2(t*timeSpeed * 0.5 , 0.0)));
		}
	}
	float fbm = fbm(uv + c_noise + vec2(t * timeSpeed , 0.0) );
	
	return fbm;
}


vec2 rotate(vec2 coord, float angle){
	coord -= 0.5;
	coord *= mat2(vec2(cos(angle),-sin(angle)),vec2(sin(angle),cos(angle)));
	return coord + 0.5;
}

void fragment(){
	vec2 uv = UV;
	float d_light = distance(uv , lightOrigin);
	
	// Calculate a fresnal effect
	vec2 p = -0.5 + uv;
	float dist = length( p );
	// Dist is less than 1, but approaches 1 as it gets to the edge.
	// Multiplying it by itself will cause edges to move towards 1, while center stays close to zero and in fact gets smaller.
	vec4 fresnal = fresnalColor * fresnalRim * 15.0 * dist * dist * dist * dist * dist * dist;
	
	// cut out a circle
	float d_circle = distance(uv, vec2(0.5));
	float a = step(d_circle, 0.5);
	float d_to_center = distance(uv, vec2(0.5));
	
	uv = rotate(uv, axisTilt);
	
	// map to sphere
	uv = spherify(uv);
	// Deprecated - We don't need to curve clouds, because we are already spherizing.
	// slightly make uv go down on the right, and up in the left
	// uv.y += smoothstep(0.0, cloudCurve, abs(uv.x-0.4) );
	uv = uv * vec2( 1.0, stretch ) * 1.0;
	uv = uv * size;
	float c = cloud_alpha( uv , TIME );
	float cNoise = cloudNoise( uv * c );
	
	// assign some colors based on cloud depth & distance from light
	// This tricky bit combines various forms of noise.
	// Each copy of the noise represents a speed of influence.
	// IE many layers of noise are compressed into a single value, which gives clouds the illusion of rising, falling and forming
	float timeNoise = smoothstep( 0.0 , 1.0 , ( sin(TIME * 0.05) - cos(TIME * 0.05) + noise( uv * 3.0 ) ) );
	
	float cloudNoise1 = fbm( (uv + ( TIME * timeSpeed ) ) * 3.0 );

	// NOTE: Use of negative time. This will allow some features to look like they are moving against the planets rotation.
	float noise1 = cloudNoise( (uv + ( TIME * timeSpeed ) ) * 1.0 );
	float noise2 = noise( (uv + ( TIME * timeSpeed * 0.55 ) ) * 2.0 );
	float noise3 = fbm( (uv - ( TIME * timeSpeed ) * 0.335 ) * 3.0 );
	float noise4 = fbm( (uv + ( TIME * timeSpeed ) * 0.255 ) * 4.0 );
	float allNoise = ( noise1 - noise2 + noise3 + noise4 ) + timeNoise * 0.1;
	
	// Trig functions on UV is just to give illision of clouds rising & falling. It's gradual enough  that planet should rotate out of view before
	// People realize it's just an ossilaction.
	float cloudColor = fbm( ( uv + ( TIME * timeSpeed ) + c * 2.0 - allNoise * 0.1 ) + cloudNoise1 );
	
	vec4 cloudSample = texture( gradient , vec2( cloudColor , 0.0 ) );
	float cloudA = cloudSample.a;
	
	vec3 col = mix( cloudSample.rgb, cloudSample.rgb * 0.10, smoothstep( 0.0 , 2.0 ,  d_light ) / 1.0 );
	col = mix( (col.rgb + ( starLight.rgb * cloudReflectence * starIntensity ) ) * 0.5, col.rgb , smoothstep( -1.0 , 1.0 , d_light * 1.0 ) );
	
	col = mix( col.rgb  , vec3( 0 , 0, 0 ) , cloudColor * 0.5 );
	col = col + vec3( fresnal.rgb );
	
	c *= step(d_to_center, 0.5);
	COLOR = vec4( col.rgb ,  smoothstep( 0.0 , cloudCover , c ) * a * cloudA );
}