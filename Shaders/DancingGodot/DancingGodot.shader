shader_type canvas_item;

uniform float timeFactor = 1.0;
uniform vec2 amplitude = vec2( 10 , 5 );

void vertex(){
	// VERTEX += cos(TIME) * vec2(20.0 , 20.0); // Move  back and forth in a diaginal
	
	// VERTEX.x += cos(TIME) * 20.0; // cos + sin gives you a circular motion
	// VERTEX.y += sin(TIME) * 20.0;
	
	VERTEX.x += cos((TIME * timeFactor) + VERTEX.x + VERTEX.y) * amplitude.x; // Get dirt cheap randomization
	VERTEX.y += sin((TIME * timeFactor) + VERTEX.y + VERTEX.x) * amplitude.y;
	
	
}