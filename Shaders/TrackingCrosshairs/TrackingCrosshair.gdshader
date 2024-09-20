shader_type canvas_item;
render_mode unshaded;

uniform sampler2D imageTexture; 
uniform vec2 center = vec2( 0.5 , 0.5 );
uniform float effectScale = 1.0;
uniform float effectRepeat = 1.0;
uniform vec2 uvMod = vec2(1.0,1.0);

uniform vec2 scrollSpeed = vec2(0.0);

uniform sampler2D circularGradiant;
uniform sampler2D textureAdd;
uniform sampler2D tinter;

// Warps and wraps UV around the center
vec2 coordinates( vec2 uv, vec2 nCenter , float scale , float repeat ){
	vec2 dir = uv - nCenter;
	float radius = length( dir ) * scale;
	float angle = atan( dir.x , dir.y ) / TAU + 0.5;
	
	return vec2( angle * repeat, radius );
}

void fragment(){
	// Polar coodinates
	vec2 uv = uvMod * coordinates( UV, center , effectScale, effectRepeat );
	// Sample Texture2D at Polar Coordinates
	vec4 mainTexture = texture( imageTexture , mod(uv + ( TIME * scrollSpeed ) , 1.0 ) );
	
	// Multiply by sampler gradiant to get colors;
	mainTexture *= texture( circularGradiant , UV );
	
	COLOR = mainTexture;
}