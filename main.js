const canvas = document.getElementById("glCanvas");
const gl = canvas.getContext("webgl2");

const vertexShaderSource = await (await fetch("shader/vertex.glsl")).text();
const fragmentShaderSource = await (await fetch("shader/fragment.glsl")).text();

// Vertex shader source
// const vertexShaderSource = `#version 300 es
//   in vec2 a_position;
//   void main() {
//     gl_Position = vec4(a_position, 0.0, 1.0);
//   }
// `;

// Fragment shader source
// const fragmentShaderSource = `#version 300 es
//   precision mediump float;

//   out vec4 fragColor;
//   void main() {
//     fragColor = vec4(0.0, 1.0, 0.0, 1.0);
//   }
// `;

const createShader = (type, source) => {
  const shader = gl.createShader(type);
  gl.shaderSource(shader, source);
  gl.compileShader(shader);
  const success = gl.getShaderParameter(shader, gl.COMPILE_STATUS);
  if (!success) {
    console.error(gl.getShaderInfoLog(shader));
    return null;
  }
  return shader;
};

const createProgram = (vertexShader, fragmentShader) => {
  const program = gl.createProgram();
  gl.attachShader(program, vertexShader);
  gl.attachShader(program, fragmentShader);
  gl.linkProgram(program);
  const success = gl.getProgramParameter(program, gl.LINK_STATUS);
  if (!success) {
    console.error(gl.getProgramInfoLog(program));
    return null;
  }
  return program;
};

const vertexShader = createShader(gl.VERTEX_SHADER, vertexShaderSource);
const fragmentShader = createShader(gl.FRAGMENT_SHADER, fragmentShaderSource);
const program = createProgram(vertexShader, fragmentShader);

function draw() {
  canvas.width = canvas.getBoundingClientRect().width;
  canvas.height = canvas.getBoundingClientRect().height;

  gl.viewport(0, 0, canvas.width, canvas.height);

  gl.useProgram(program);

  gl.uniform2f(
    gl.getUniformLocation(program, "u_resolution"),
    canvas.width,
    canvas.height,
  );

  const fps = 12;
  gl.uniform1f(
    gl.getUniformLocation(program, "u_time"),
    Math.floor((fps * performance.now()) / 1000) / fps,
  );

  gl.drawArrays(gl.TRIANGLES, 0, 3);

  requestAnimationFrame(draw);
}

draw();
