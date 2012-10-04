// define our rectangular texture samplers 
uniform sampler2DRect tex0; 

// define our varying texture coordinates 
//varying vec2 texcoord0; 
//varying vec2 texdim0; 

void main (void) 
{ /*
// we have to average like so:	
// scanline 0 and 1 are (0 + 1) / 2. 
// scanline 2 and 3 are (2 + 3) / 2. 

// we need to not do 
// scanline 0 and 1 are (0 + 1) / 2. 
// scanline 1 and 2 are (1 + 2) / 2. 

float isodd = mod(texcoord0.y, 2.0); // returns 0 or 1. 

vec4 result; 

if(bool(isodd)) 
{ 
vec4 evenfield = texture2DRect(tex0, vec2(texcoord0.x, texcoord0.y + 1.0)); 
vec4 oddfield = texture2DRect(tex0, texcoord0); 

result = mix(evenfield, oddfield, 0.5); 
} 

else 
{	
vec4 evenfield = texture2DRect(tex0, texcoord0); 
vec4 oddfield = texture2DRect(tex0, vec2(texcoord0.x, texcoord0.y - 1.0)); 

result = mix(evenfield, oddfield, 0.5); 
} 
*/
//gl_FragColor = result; 
	vec2 st = gl_TexCoord[0].st;

	gl_FragColor = gl_Color * texture2DRect(tex0, st );

// moo : short cow ! 
} 
