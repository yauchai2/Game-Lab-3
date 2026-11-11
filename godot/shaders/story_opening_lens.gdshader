shader_type canvas_item;
render_mode unshaded;
// Story opening lens: barrel fisheye, radial and directional smear, chroma split,
// impact flash and the black/white/magenta ink grade used for the title card.
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform float fisheye = 0.0;
uniform float blur = 0.0;
uniform vec2 smear = vec2(0.0);
uniform float chroma = 0.0;
uniform float flash = 0.0;
uniform float ink = 0.0;
uniform float invert = 0.0;
uniform float vignette = 0.25;
uniform float fade = 0.0;
uniform vec2 center = vec2(0.5,0.5);
vec2 keep(vec2 uv) { return clamp(uv,vec2(0.002),vec2(0.998)); }
void fragment() {
	vec2 q = SCREEN_UV-vec2(0.5);
	float r2 = dot(q*vec2(1.777778,1.0),q*vec2(1.777778,1.0));
	vec2 uv = keep(vec2(0.5)+q*(1.0+fisheye*0.72*r2)/(1.0+fisheye*0.75));
	vec2 radial = uv-center;
	float rim = smoothstep(0.06,0.55,length(radial*vec2(1.0,0.5625)));
	vec3 color = vec3(0.0);
	for (int i=0;i<8;i++) {
		float tap = float(i)/7.0;
		vec2 at = keep(uv-radial*blur*rim*tap+smear*(tap-0.5));
		vec3 s = texture(screen_texture,at).rgb;
		if (chroma>0.0) {
			s.r = texture(screen_texture,keep(at+radial*chroma*rim)).r;
			s.b = texture(screen_texture,keep(at-radial*chroma*rim)).b;
		}
		color += s;
	}
	color /= 8.0;
	if (ink>0.0) {
		float high = max(color.r,max(color.g,color.b));
		float low = min(color.r,min(color.g,color.b));
		float luma = dot(color,vec3(0.299,0.587,0.114));
		// Saturated paint (sky, jackets, hair, cyan trim) stays flat; everything else is ink.
		float paint = smoothstep(0.5,0.62,(high-low)/max(high,0.001))*step(0.22,high);
		vec3 flat_paint = floor(color/max(high,0.001)*4.0+0.5)/4.0*(high>0.55?1.0:0.72);
		vec3 mono = vec3(step(0.36,luma));
		color = mix(color,mix(mono,flat_paint,paint),ink);
	}
	color = mix(color,vec3(1.0)-color,invert);
	color *= 1.0-rim*rim*vignette;
	color = mix(color,vec3(1.0),clamp(flash,0.0,1.0));
	color = mix(color,vec3(0.03,0.02,0.05),clamp(fade,0.0,1.0));
	COLOR = vec4(color,1.0);
}
