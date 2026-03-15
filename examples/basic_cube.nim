import std/[os, math]
import pixie, pixie/fileformats/png
import vmath
import windy
import ../src/ogl

const
  Width = 1280
  Height = 800
  TextureSize = 128
  TexturePath = currentSourcePath().parentDir() / "testTexture.png"

  VertShader = """
#version 450 core
layout(location = 0) in vec3 aPosition;
layout(location = 1) in vec2 aUV;
uniform mat4 uMVP;
out vec2 vUV;
void main() {
    gl_Position = uMVP * vec4(aPosition, 1.0);
    vUV = aUV;
}
"""

  FragShader = """
#version 450 core
in vec2 vUV;
out vec4 fragColor;
uniform sampler2D uTexture;
void main() {
    fragColor = texture(uTexture, vUV);
}
"""

type
  CubeVertex = object
    position: array[3, float32]
    uv: array[2, float32]

const CubeVertices = [
  # Front
  CubeVertex(position: [-1.0'f32,  1.0, 1.0], uv: [0.0'f32, 0.0]),
  CubeVertex(position: [ 1.0'f32, -1.0, 1.0], uv: [1.0'f32, 1.0]),
  CubeVertex(position: [ 1.0'f32,  1.0, 1.0], uv: [1.0'f32, 0.0]),
  CubeVertex(position: [-1.0'f32,  1.0, 1.0], uv: [0.0'f32, 0.0]),
  CubeVertex(position: [-1.0'f32, -1.0, 1.0], uv: [0.0'f32, 1.0]),
  CubeVertex(position: [ 1.0'f32, -1.0, 1.0], uv: [1.0'f32, 1.0]),
  # Back
  CubeVertex(position: [ 1.0'f32,  1.0, -1.0], uv: [0.0'f32, 0.0]),
  CubeVertex(position: [-1.0'f32, -1.0, -1.0], uv: [1.0'f32, 1.0]),
  CubeVertex(position: [-1.0'f32,  1.0, -1.0], uv: [1.0'f32, 0.0]),
  CubeVertex(position: [ 1.0'f32,  1.0, -1.0], uv: [0.0'f32, 0.0]),
  CubeVertex(position: [ 1.0'f32, -1.0, -1.0], uv: [0.0'f32, 1.0]),
  CubeVertex(position: [-1.0'f32, -1.0, -1.0], uv: [1.0'f32, 1.0]),
  # Left
  CubeVertex(position: [-1.0'f32,  1.0, -1.0], uv: [0.0'f32, 0.0]),
  CubeVertex(position: [-1.0'f32, -1.0,  1.0], uv: [1.0'f32, 1.0]),
  CubeVertex(position: [-1.0'f32,  1.0,  1.0], uv: [1.0'f32, 0.0]),
  CubeVertex(position: [-1.0'f32,  1.0, -1.0], uv: [0.0'f32, 0.0]),
  CubeVertex(position: [-1.0'f32, -1.0, -1.0], uv: [0.0'f32, 1.0]),
  CubeVertex(position: [-1.0'f32, -1.0,  1.0], uv: [1.0'f32, 1.0]),
  # Right
  CubeVertex(position: [1.0'f32,  1.0,  1.0], uv: [0.0'f32, 0.0]),
  CubeVertex(position: [1.0'f32, -1.0, -1.0], uv: [1.0'f32, 1.0]),
  CubeVertex(position: [1.0'f32,  1.0, -1.0], uv: [1.0'f32, 0.0]),
  CubeVertex(position: [1.0'f32,  1.0,  1.0], uv: [0.0'f32, 0.0]),
  CubeVertex(position: [1.0'f32, -1.0,  1.0], uv: [0.0'f32, 1.0]),
  CubeVertex(position: [1.0'f32, -1.0, -1.0], uv: [1.0'f32, 1.0]),
  # Top
  CubeVertex(position: [-1.0'f32, 1.0, -1.0], uv: [0.0'f32, 0.0]),
  CubeVertex(position: [ 1.0'f32, 1.0,  1.0], uv: [1.0'f32, 1.0]),
  CubeVertex(position: [ 1.0'f32, 1.0, -1.0], uv: [1.0'f32, 0.0]),
  CubeVertex(position: [-1.0'f32, 1.0, -1.0], uv: [0.0'f32, 0.0]),
  CubeVertex(position: [-1.0'f32, 1.0,  1.0], uv: [0.0'f32, 1.0]),
  CubeVertex(position: [ 1.0'f32, 1.0,  1.0], uv: [1.0'f32, 1.0]),
  # Bottom
  CubeVertex(position: [-1.0'f32, -1.0,  1.0], uv: [0.0'f32, 0.0]),
  CubeVertex(position: [ 1.0'f32, -1.0, -1.0], uv: [1.0'f32, 1.0]),
  CubeVertex(position: [ 1.0'f32, -1.0,  1.0], uv: [1.0'f32, 0.0]),
  CubeVertex(position: [-1.0'f32, -1.0,  1.0], uv: [0.0'f32, 0.0]),
  CubeVertex(position: [-1.0'f32, -1.0, -1.0], uv: [0.0'f32, 1.0]),
  CubeVertex(position: [ 1.0'f32, -1.0, -1.0], uv: [1.0'f32, 1.0]),
]

proc mat4ToArray(m: Mat4): array[16, float32] =
  var i = 0
  for col in 0 ..< 4:
    for row in 0 ..< 4:
      result[i] = m[col, row]
      inc i

proc ensureTextureFile() =
  if fileExists(TexturePath):
    return

  var pixels = newSeq[uint8](TextureSize * TextureSize * 4)
  for y in 0 ..< TextureSize:
    for x in 0 ..< TextureSize:
      let
        idx = (y * TextureSize + x) * 4
        tile =
          if ((x div 16) + (y div 16)) mod 2 == 0:
            [255'u8, 255'u8, 255'u8]
          else:
            [32'u8, 128'u8, 255'u8]
      pixels[idx + 0] = tile[0]
      pixels[idx + 1] = tile[1]
      pixels[idx + 2] = tile[2]
      pixels[idx + 3] = 255

  writeFile(TexturePath, encodePng(TextureSize, TextureSize, 4, addr pixels[0], pixels.len))

proc loadTexture(): ogl.Texture =
  ensureTextureFile()
  let img = readImage(TexturePath)
  var pixelBytes = newSeq[uint8](img.width * img.height * 4)
  for y in 0 ..< img.height:
    let srcIdx = img.dataIndex(0, y)
    let srcPtr = cast[ptr uint8](img.data[srcIdx].addr)
    copyMem(addr pixelBytes[y * img.width * 4], srcPtr, img.width * 4)

  let mipLevels = int(floor(log2(max(img.width, img.height).float32))) + 1
  result = newTexture2D(InternalFormat.RGBA8, img.width, img.height, mipLevels)
  result.upload(img.width, img.height, PixelFormat.RGBA, PixelType.UByte, addr pixelBytes[0])
  result.generateMipmaps()
  result.minFilter = TextureFilter.LinearMipmapLinear
  result.magFilter = TextureFilter.Linear
  result.wrapS = WrapMode.Repeat
  result.wrapT = WrapMode.Repeat

when isMainModule:
  let window = newWindow("OpenGL 4.6 DSA - Basic Cube", ivec2(Width, Height), msaa = msaa4x)
  makeContextCurrent(window)
  ogl.init()

  var program = newProgram(VertShader, FragShader)
  let mvpLoc = program.uniformLoc("uMVP")
  var texture = loadTexture()

  var vbo = newBuffer(CubeVertices, BufferUsage.StaticDraw)
  var vao = newVertexArray()
  vao.addBuffer(vbo, [
    attr(0, 3, float32),
    attr(1, 2, float32),
  ])

  program.setUniform("uTexture", 0'i32)

  ogl.enable(Capability.DepthTest)
  ogl.depthFunc(CompareFunc.Less)
  ogl.enable(Capability.CullFace)
  ogl.cullFace(Face.Back)
  ogl.frontFace(Winding.CCW)
  ogl.enable(Capability.Multisample)
  ogl.clearColor(0.05, 0.05, 0.1, 1.0)

  var frameCounter: uint64 = 0

  window.onResize = proc() =
    let size = window.size
    if size.x > 0 and size.y > 0:
      ogl.viewport(0, 0, size.x.int, size.y.int)

  while not window.closeRequested:
    pollEvents()
    let
      size = window.size
      aspect = size.x.float32 / max(1, size.y).float32
      time = frameCounter.float32 / 60.0'f32
      model =
        translate(vec3(0.0'f32, 0.0'f32, -5.0'f32)) *
        rotateY(time * 0.7'f32) *
        rotateX(time * 0.35'f32)
      proj = perspective(60.0'f32, aspect, 0.1'f32, 100.0'f32)
      mvp = proj * model
    var transform = mat4ToArray(mvp)

    ogl.clear({ClearBit.Color, ClearBit.Depth})
    program.use()
    program.setUniformMat4(mvpLoc, transform)
    texture.bindToUnit(0)
    vao.bindVao()
    ogl.drawArrays(Primitive.Triangles, 0, CubeVertices.len)

    window.swapBuffers()
    inc frameCounter

  destroy(vao)
  destroy(vbo)
  destroy(texture)
  destroy(program)
