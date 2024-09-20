shader_type canvas_item;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture , filter_linear_mipmap;


uniform float strength : hint_range( 0.1 , 40 ) = 1;
uniform float size : hint_range( 0.0, 5.0 ) = 1.0;
uniform float initRotation : hint_range( 0.0 , 6.28 ) = 0.0;
uniform float rotation : hint_range( 0.0, 6.28 ) = 0.0;
uniform vec2 origin = vec2( 0.5 , 0.5);
uniform sampler2D curve;

const vec2 ASPECT_RATIO = vec2( 1.6 , 1.0 );

mat2 rotate( float a ){
	// Takes an angle in Radians
	float s = sin(a);
	float c = cos(a);

	// Returns a 2d Rotation Matrix
	return mat2( vec2( c, -s ), vec2(s , c) );
}

vec2 coordRotate(vec2 coord, float angle){
	coord -= 0.5;
	coord *= mat2(vec2(cos(angle),-sin(angle)),vec2(sin(angle),cos(angle)));
	return coord + 0.5;
}

void fragment(){
	// Calculates the center on the basis of the Aspect ratio. This forces the warping to be mostly circular.
	vec2 uv = coordRotate( UV , rotation );
	vec2 vecToCenter = (origin - uv);
	
	float distToCenter = length( vecToCenter );
	
	float curveVal = texture( curve, vec2( distToCenter ) * size ).r;
	vec2 diff = normalize( vecToCenter  ) * 0.6 * curveVal * strength;

	COLOR = texture( SCREEN_TEXTURE , SCREEN_UV - diff );
}