shader_type canvas_item;

uniform float tileFactor = 10.0;
uniform float aspectRatio = 0.5;

uniform sampler2D uvOffsetTexture : hint_black;
uniform vec2 uvOffsetScale = vec2(1.0 , 1.0);

uniform float timeScale = 0.02;
uniform vec2 waveSize = vec2( 1 , 1 );

void fragment(){
	// My offset values
	vec2 offsetTextureUVs = UV * uvOffsetScale;
	offsetTextureUVs += TIME * timeScale;
	
	// Red represents shift on X axis.
	// Green represents shift on Y Axis. 
	// With shaders, important to think about colors as interchangable with positions , time and other vectors

	// This is a swizzle. Grabbing only 2 params from texture, the RG channels.
	vec2 textureBasedOffset = texture( uvOffsetTexture , offsetTextureUVs ).rg;
	// Here we normalize the values between -1 and 1 since we want a deformation in both directions.
	textureBasedOffset = textureBasedOffset * 2.0 - 1.0;
	
	vec2 adjustedUVs = UV * tileFactor;
	adjustedUVs.y *= aspectRatio;
	
	COLOR = texture( TEXTURE , adjustedUVs + textureBasedOffset * waveSize );
	NORMALMAP = texture( NORMAL_TEXTURE, UV + textureBasedOffset * 0.5 ).rgb;
	//COLOR = vec4( textureBasedOffset , vec2( 0.0 , 1.0 ) );
}