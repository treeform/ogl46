import windy
import ../src/ogl

type
  TriangleVertex = object
    position: array[3, float32]
    color: array[3, float32]

const
  Width = 1280
  Height = 800

  VertShader = """
#version 450 core
layout(location = 0) in vec3 aPosition;
layout(location = 1) in vec3 aColor;
out vec3 vColor;
void main() {
    gl_Position = vec4(aPosition, 1.0);
    vColor = aColor;
}
"""

  FragShader = """
#version 450 core
in vec3 vColor;
out vec4 fragColor;
void main() {
    fragColor = vec4(vColor, 1.0);
}
"""

  Vertices = [
    TriangleVertex(
      position: [0.0'f32, 0.5'f32, 0.0'f32],
      color: [1.0'f32, 0.0'f32, 0.0'f32]
    ),
    TriangleVertex(
      position: [0.5'f32, -0.5'f32, 0.0'f32],
      color: [0.0'f32, 1.0'f32, 0.0'f32]
    ),
    TriangleVertex(
      position: [-0.5'f32, -0.5'f32, 0.0'f32],
      color: [0.0'f32, 0.0'f32, 1.0'f32]
    )
  ]

when isMainModule:
  let window = newWindow("OpenGL 4.6 DSA - Basic Triangle", ivec2(Width, Height))
  makeContextCurrent(window)
  ogl.init()

  var program = newProgram(VertShader, FragShader)

  var vbo = newBuffer(Vertices, BufferUsage.StaticDraw)
  var vao = newVertexArray()
  vao.addBuffer(vbo, [
    attr(0, 3, float32),
    attr(1, 3, float32),
  ])

  ogl.clearColor(0.05, 0.05, 0.1, 1.0)

  while not window.closeRequested:
    pollEvents()

    ogl.clear({ClearBit.Color})
    program.use()
    vao.bindVao()
    ogl.drawArrays(Primitive.Triangles, 0, Vertices.len)

    window.swapBuffers()

  destroy(vao)
  destroy(vbo)
  destroy(program)
