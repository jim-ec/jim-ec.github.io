#version 300 es

in vec2 a_position;

// out vec2 pos;

// void main() {
//     gl_Position = vec4(a_position, 0.0, 1.0);
// }

void main() {
    // Compute the normalized quad coordinates based on the vertex index.
    // #: 0 1 2
    // x: 0 1 0
    // y: 0 0 1
    uvec2 uv = (uvec2(gl_VertexID) & uvec2(1u, 2u)) << uvec2(1u, 0u);

    // var out: VertexOutput;
    gl_Position = vec4(vec2(uv << uvec2(1u)) - 1.0, 0.0, 1.0);

    // pos = vec2(uv) - 0.5;

    // out.uv = vec2<f32>(uv) - 0.5;
    // return out;
}
