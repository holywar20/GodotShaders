shader_type canvas_item;

uniform vec2 tiledFactor = vec2( 5.0 , 5.0 );
uniform float aspectRatio = 0.5;

uniform vec2 offsetScale = vec2(2.0 , 2.0);
uniform vec2 amplitude = vec2( 0.02, 0.05 );
uniform vec2 timeScale = vec2( 1.0, 1.0 );

void fragment(){
	// COLOR = vec4( 0.0 , 1.0 , 0.0 , 1.0 ); # Flat color. Sort of useless, but it exists
	// # NOTE Aspect ratio will not work unless import is set with the Repeat flag set to 'enabled'
	// Handle aspect ratio in code
	vec2 tiledUVs = UV * tiledFactor;
	tiledUVs.y *= aspectRatio;
	// COLOR = vec4( tiledUVs , 0.0 , 1.0 ); // Utilizing UV for testing and visualisation of shaders
	
	// Now we calculate & animate an offset based on time
	vec2 wavesUVOffset;
	wavesUVOffset.x = cos((TIME * timeScale.x )  + (tiledUVs.x + tiledUVs.y) * offsetScale.x);
	wavesUVOffset.y = sin((TIME * timeScale.y ) + (tiledUVs.y + tiledUVs.x) * offsetScale.y);
	
	
	//COLOR = vec4( wavesUVOffset / 0.05 , 0.0 , 1.0 );  // Visualizing a wave pattern
	COLOR = texture( TEXTURE , tiledUVs + wavesUVOffset * amplitude );
}