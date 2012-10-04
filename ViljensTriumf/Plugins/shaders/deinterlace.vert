//varying vec2 texcoord0; 
//varying vec2 texdim0; 

void main() {
	gl_TexCoord[0] = gl_MultiTexCoord0;
	gl_Position = ftransform();
    
   // texcoord0 = vec2(0,0);
  //  texdim0 = vec2(720,576);
}