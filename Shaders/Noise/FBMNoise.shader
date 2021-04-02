shader_type canvas_item;

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

// Creates a blockyish kind of noise.
float value_noise( vec2 coord ){
	vec2 integer = floor(coord); // Integer part of number
	vec2 floatPoint = fract(coord); // Fractional part of number
	
	// Now we find vectors for the 4 corners
	float topLeft = rand( integer );
	float topRight = rand( integer + vec2(1.0 , 0.0));
	float botLeft = rand( integer + vec2(0.0 , 1.0));
	float botRight = rand( integer + vec2(1.0 , 1.0));
	
	// Get a cubic position factor. 
	// IE find diff between pixel vs. corners, but follow a standard cubic curve for smoothing
	vec2 cubic = floatPoint * floatPoint * ( 3.0 - 2.0 * floatPoint );
	
	// Now do a mix on all these based on the axis they share. 
	float topMix = mix( topLeft , topRight , cubic.x);
	float botMix = mix( botLeft , botRight, cubic.x);
	float wholeMix = mix( topMix, botMix, cubic.y );
	
	return wholeMix;
}

// Basic perlin Noise
float perlin_noise( vec2 coord ){
	vec2 integer = floor(coord); // Integer part of number
	vec2 floatPoint = fract(coord); // Fractional part of number
	
	// Now we find vectors for the 4 corners to the pixel
	// Multiply the values by 2 x PI
	float topLeft = rand( integer ) * 6.283;
	float topRight = rand( integer + vec2(1.0 , 0.0)) * 6.283;
	float botLeft = rand( integer + vec2(0.0 , 1.0)) * 6.283;
	float botRight = rand( integer + vec2(1.0 , 1.0)) * 6.283;
	
	// Now we perform a rotation Matrix using trig functions.
	vec2 tlVec = vec2(-sin(topLeft) , cos(topLeft));
	vec2 trVec = vec2(-sin(topRight) , cos(topRight));
	vec2 blVec = vec2(-sin(botLeft) , cos(botLeft));
	vec2 brVec = vec2(-sin(botRight) , cos(botRight));
	
	float tlDot = dot( tlVec, floatPoint);
	float trDot = dot( trVec, floatPoint - vec2( 1.0 , 0.0));
	float blDot = dot( blVec, floatPoint - vec2( 0.0 , 1.0));
	float brDot = dot( brVec, floatPoint - vec2( 1.0 , 1.0));

	vec2 cubic = floatPoint * floatPoint * ( 3.0 - 2.0 * floatPoint );

	float topMix = mix( tlDot , trDot , cubic.x);
	float botMix = mix( blDot , brDot, cubic.x);
	float wholeMix = mix( topMix, botMix, cubic.y );
	
	// We offset by 0.5 because the noise in question is generating a value between 0.5 and -0.5
	return wholeMix + 0.5;
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
	int OCTAVES = 8;
	
	float normalize_factor = 0.0;
	float value = 0.0;
	float scale = 0.5;
	
	for(int i = 0; i < OCTAVES; i++){
		
		normalize_factor += scale;
		
		if( i % 2 == 0 )
			value += vornoi_noise( coord ) * scale;
		else
			value += perlin_noise( coord ) * scale;

		coord *= 2.0;
		scale *= 0.5;
	}
	
	return value / normalize_factor;
}

void fragment(){
	// Multiply Coordinates by 10 because we want to use floor & fract to seperate out integer from decimal parts
	vec2 coord = UV * 10.0;
	
	float value = fbm(coord);
	
	COLOR = vec4( vec3(value) , 1.0 );
}

