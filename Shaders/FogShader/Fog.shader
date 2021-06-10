shader_type canvas_item;

uniform vec3 color = vec3( 0.35 , 0.55 , 0.53 );
uniform int octave = 4;

float rand( vec2 coord ){
	return fract(sin(dot(coord, vec2(12.9898, 78.233))) * 43758.5453);
}

float pNoise( vec2 coord ){
	vec2 i = floor(coord);
	vec2 f = fract(coord);
	
	// Find the 4 corners
	float a = rand(i);
	float b = rand(i + vec2(1.0 , 0.0) );
	float c = rand(i + vec2(0.0 , 1.0) );
	float d = rand(i + vec2(1.0 , 1.0) );
	
	vec2 cubic = f * f * (3.0 - 2.0 * f);
	
	return mix( a , b, cubic.x) + ( c - a ) * cubic.y * ( 1.0 - cubic.x ) + (d - b) * cubic.x * cubic.y;
}

float fbm( vec2 coord ){
	float value = 0.0;
	float scale = 0.5;

	for(int x = 0; x < octave; x++){
		value += pNoise(coord) * scale;
		coord *= 2.0;
		scale *= 0.5;
	}
	
	return value;
}

void fragment(){
	vec2 coord = UV * 15.0;
	
	vec2 motion = vec2( fbm(vec2( coord.x + TIME * 0.5 , coord.y + TIME * -0.5 ) ) );
	
	float final = fbm(coord + motion);
	
	COLOR = vec4( color , final * 0.5 );
}