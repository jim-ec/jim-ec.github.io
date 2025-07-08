#version 300 es

precision mediump float;

uniform vec2 u_resolution;
uniform float u_time;

out vec4 fragColor;

const float PI = 3.14159265;

float hash(vec3 p) {
    return fract(sin(dot(p, vec3(127.1, 311.7, 74.7))) * 43758.5453);
}

vec3 rotateAroundAxis(vec3 v, vec3 axis, float angle) {
    axis = normalize(axis);
    float cosAngle = cos(angle);
    float sinAngle = sin(angle);
    return v * cosAngle +
        cross(axis, v) * sinAngle +
        axis * dot(axis, v) * (1.0 - cosAngle);
}

float perlin(vec3 p) {
    vec3 ip = floor(p);
    vec3 fp = smoothstep(0.0, 1.0, fract(p));

    float c000 = hash(ip);
    float c100 = hash(ip + vec3(1, 0, 0));
    float c010 = hash(ip + vec3(0, 1, 0));
    float c110 = hash(ip + vec3(1, 1, 0));
    float c001 = hash(ip + vec3(0, 0, 1));
    float c101 = hash(ip + vec3(1, 0, 1));
    float c011 = hash(ip + vec3(0, 1, 1));
    float c111 = hash(ip + vec3(1, 1, 1));

    float c00 = mix(c000, c100, fp.x);
    float c10 = mix(c010, c110, fp.x);
    float c01 = mix(c001, c101, fp.x);
    float c11 = mix(c011, c111, fp.x);

    float c0 = mix(c00, c10, fp.y);
    float c1 = mix(c01, c11, fp.y);

    return mix(c0, c1, fp.z);
}

vec3 hex(int h) {
    return vec3(
        float((h & 0xff0000) >> 16) / 255.0,
        float((h & 0x00ff00) >> 8) / 255.0,
        float((h & 0x0000ff) >> 0) / 255.0
    );
}

void main() {
    vec2 fragCoord = gl_FragCoord.xy / u_resolution;

    // Shift from [0, 1] to [-1, 1]
    fragCoord *= 2.0;
    fragCoord -= 1.0;

    // Aspect ratio correction, keep content contained
    if (u_resolution.x > u_resolution.y) {
        fragCoord.x *= u_resolution.x / u_resolution.y;
    } else {
        fragCoord.y *= u_resolution.y / u_resolution.x;
    }

    float pixelsPerUnit = 64.0;
    float pixelsPerDitherCell = 4.0;
    float ditherCellsPerUnit = pixelsPerUnit / pixelsPerDitherCell;

    vec2 iPixel = floor(fragCoord * pixelsPerUnit);
    vec2 iDitherCell = floor(fragCoord * ditherCellsPerUnit);
    vec2 iDitherPixel = mod(iPixel, pixelsPerDitherCell);

    bool opaque = false;
    int color;

    int waterLevels[4] = int[4](0x30488c, 0x3a72ab, 0x53accc, 0x76d5e0);
    int grassLevels[4] = int[4](0x165a4c, 0x1ebc73, 0x91db69, 0xcddf6c);
    int cloudLevels[4] = int[4](0x3e3546, 0x7f708a, 0xc7dcd0, 0xffffff);
    int dark = 0x2e222f;

    // The lighting is quantized towards negative infinity.
    // The larger the quantization error, the closer we are to the next brighter quantization level,
    // and we need more bright pixels.
    mat4 ditherMatrices[4] = mat4[4](
            mat4(
                vec4(0.0, 0.0, 0.0, 0.0),
                vec4(0.0, 0.0, 0.0, 0.0),
                vec4(0.0, 0.0, 0.0, 0.0),
                vec4(0.0, 0.0, 0.0, 0.0)
            ),
            mat4(
                vec4(0.0, 0.0, 0.0, 0.0),
                vec4(0.0, 1.0, 1.0, 0.0),
                vec4(0.0, 1.0, 1.0, 0.0),
                vec4(0.0, 0.0, 0.0, 0.0)
            ),
            mat4(
                vec4(1.0, 1.0, 1.0, 1.0),
                vec4(1.0, 0.0, 0.0, 1.0),
                vec4(1.0, 0.0, 0.0, 1.0),
                vec4(1.0, 1.0, 1.0, 1.0)
            ),
            mat4(
                vec4(0.0, 1.0, 1.0, 0.0),
                vec4(1.0, 1.0, 1.0, 1.0),
                vec4(1.0, 1.0, 1.0, 1.0),
                vec4(0.0, 1.0, 1.0, 0.0)
            )
        );

    vec3 sun = normalize(vec3(2.0, 0.0, 2.0));
    sun = rotateAroundAxis(sun, normalize(vec3(0.0, 1.0, 0.0)), 0.1 * u_time);

    vec3 planetAxis = normalize(vec3(0.5, 1.0, 0.0));

    vec3 p;
    float disc;

    p = vec3(iPixel, 0.0) / pixelsPerUnit / 0.8;
    disc = 1.0 - p.x * p.x - p.y * p.y;
    if (disc >= 0.0) {
        p.z = sqrt(disc);

        float lit = dot(normalize(p), sun); // [0, 1]
        float quantizationLevels = 4.0;
        float litQuantized = floor(quantizationLevels * lit) / quantizationLevels; // [0, 1] and is always <= lit
        float quantizationError = lit - litQuantized; // [0, 1 / quantization levels]
        mat4 ditherMatrix = ditherMatrices[int(quantizationLevels * quantizationLevels * quantizationError)];
        int iLevelIndex = int(min(
                    quantizationLevels * litQuantized
                        + ditherMatrix[int(iDitherPixel.x)][int(iDitherPixel.y)],
                    quantizationLevels
                ));

        p = rotateAroundAxis(p, planetAxis, 0.2 * u_time);

        float height = 0.8 * perlin(4.0 * p + 100.0)
                + 0.2 * perlin(12.0 * p + 200.0)
                + 0.1 * perlin(16.0 * p + 300.0);

        if (lit < 0.0) {
            color = dark;
        } else if (height < 0.5) {
            color = waterLevels[iLevelIndex];
        } else {
            color = grassLevels[iLevelIndex];
        }

        opaque = true;
    }

    p = vec3(iPixel, 0.0) / pixelsPerUnit / 0.85;
    disc = 1.0 - p.x * p.x - p.y * p.y;
    if (disc >= 0.0) {
        p.z = sqrt(disc);

        float lit = dot(normalize(p), sun); // [0, 1]
        float quantizationLevels = 4.0;
        float litQuantized = floor(quantizationLevels * lit) / quantizationLevels; // [0, 1] and is always <= lit
        float quantizationError = lit - litQuantized; // [0, 1 / quantization levels]
        mat4 ditherMatrix = ditherMatrices[int(quantizationLevels * quantizationLevels * quantizationError)];
        int iLevelIndex = int(min(
                    quantizationLevels * litQuantized
                        + ditherMatrix[int(iDitherPixel.x)][int(iDitherPixel.y)],
                    quantizationLevels
                ));

        p = rotateAroundAxis(p, planetAxis, 0.3 * u_time);

        float cloud = 0.7 * perlin(4.0 * p + 100.0 + 0.2 * u_time)
                + 0.3 * perlin(8.0 * p + 200.0 + 0.3 * u_time)
                + 0.15 * perlin(12.0 * p + 300.0 + 0.4 * u_time);
        if (cloud > 0.6) {
            color = cloudLevels[iLevelIndex];
            opaque = true;
        }
    }

    if (!opaque) discard;

    fragColor = vec4(hex(color), 1.0);
}
