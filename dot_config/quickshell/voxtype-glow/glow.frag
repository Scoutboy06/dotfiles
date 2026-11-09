#version 440
// Rebuild: /usr/lib/qt6/bin/qsb --glsl "100 es,120,150" --hlsl 50 --msl 12 -o glow.frag.qsb glow.frag
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float phase;
    vec2 resolution;
    float cornerRadius;
    float outerPadding;
};

// Smooth evolving value noise; original implementation inspired by Aurora's
// noise-shaped edge band (https://github.com/tornikegomareli/Aurora).
float hash(vec3 p) {
    return fract(sin(dot(p, vec3(91.7, 157.3, 231.9))) * 19431.371);
}
float noise(vec3 p) {
    vec3 i = floor(p), f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    return mix(mix(mix(hash(i), hash(i + vec3(1,0,0)), f.x),
                   mix(hash(i + vec3(0,1,0)), hash(i + vec3(1,1,0)), f.x), f.y),
               mix(mix(hash(i + vec3(0,0,1)), hash(i + vec3(1,0,1)), f.x),
                   mix(hash(i + vec3(0,1,1)), hash(i + vec3(1,1,1)), f.x), f.y), f.z);
}

void main() {
    vec2 p = (qt_TexCoord0 - 0.5) * resolution;
    vec2 frameSize = max(vec2(1.0), resolution - 2.0 * outerPadding);
    float radius = min(cornerRadius, min(frameSize.x, frameSize.y) * 0.5);
    vec2 q = abs(p) - frameSize * 0.5 + radius;
    float sdf = length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - radius;
    // sdf == 0 is the actual window border, not the padded drawing boundary.
    // Both wave fronts grow from this same fixed contour, with a smaller
    // outward reach. Padding is only transparent space in which to draw.
    vec2 uv = p / 260.0;
    float n = noise(vec3(uv + vec2(phase * 0.3, -phase * 0.2), phase * 0.4));
    float detail = noise(vec3(uv * 2.2 - phase * 0.2, phase * 0.3));
    float reach = 10.0 + 27.0 * n + 9.0 * detail;
    float outwardReach = 3.0 + 5.0 * n + 2.0 * detail;
    float distanceFromBorder = sdf < 0.0 ? -sdf / reach : sdf / outwardReach;
    float band = 1.0 - smoothstep(0.25, 1.0, distanceFromBorder);
    float haze = exp(-distanceFromBorder / 0.85);
    float rim = exp(-abs(sdf) / 3.0);
    float canvasFade = 1.0 - smoothstep(outerPadding - 5.0, outerPadding - 1.0, max(0.0, sdf));
    float angle = atan(p.y, p.x);
    float hue = angle - phase + 0.3 * sin(2.0 * angle + phase);
    vec3 color = 0.55 + 0.45 * cos(hue + vec3(0.0, 2.1, 4.2));
    color = mix(color, vec3(0.45, 0.25, 1.0), 0.25);
    float alpha = canvasFade * min(0.70, 0.46 * band + 0.16 * haze + 0.08 * rim);
    fragColor = vec4(color * alpha, alpha) * qt_Opacity;
}
