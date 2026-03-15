import std/os
import pixie, pixie/fileformats/png
import windy
import ../src/ogl

type
  QuadVertex = object
    position: array[3, float32]
    color: array[3, float32]
    uv: array[2, float32]

const
  Width = 1280
  Height = 800
  TextureSize = 128
  TexturePath = currentSourcePath().parentDir() / "testTexture.png"

  VertShader = """
#version 450 core
layout(location = 0) in vec3 aPosition;
layout(location = 1) in vec3 aColor;
layout(location = 2) in vec2 aUV;
out vec3 vColor;
out vec2 vUV;
void main() {
    gl_Position = vec4(aPosition, 1.0);
    vColor = aColor;
    vUV = aUV;
}
"""

  FragShader = """
#version 450 core
in vec3 vColor;
in vec2 vUV;
out vec4 fragColor;
uniform sampler2D uTexture;
void main() {
    fragColor = texture(uTexture, vUV);
}
"""

  Vertices = [
    QuadVertex(
      position: [-0.5'f32, 0.5'f32, 0.0'f32],
      color: [1.0'f32, 0.0'f32, 0.0'f32],
      uv: [0.0'f32, 0.0'f32]
    ),
    QuadVertex(
      position: [0.5'f32, 0.5'f32, 0.0'f32],
      color: [0.0'f32, 1.0'f32, 0.0'f32],
      uv: [1.0'f32, 0.0'f32]
    ),
    QuadVertex(
      position: [0.5'f32, -0.5'f32, 0.0'f32],
      color: [0.0'f32, 0.0'f32, 1.0'f32],
      uv: [1.0'f32, 1.0'f32]
    ),
    QuadVertex(
      position: [-0.5'f32, 0.5'f32, 0.0'f32],
      color: [1.0'f32, 0.0'f32, 0.0'f32],
      uv: [0.0'f32, 0.0'f32]
    ),
    QuadVertex(
      position: [0.5'f32, -0.5'f32, 0.0'f32],
      color: [0.0'f32, 0.0'f32, 1.0'f32],
      uv: [1.0'f32, 1.0'f32]
    ),
    QuadVertex(
      position: [-0.5'f32, -0.5'f32, 0.0'f32],
      color: [1.0'f32, 1.0'f32, 0.0'f32],
      uv: [0.0'f32, 1.0'f32]
    )
  ]

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

  result = newTexture2D(InternalFormat.RGBA8, img.width, img.height)
  result.upload(img.width, img.height, PixelFormat.RGBA, PixelType.UByte, addr pixelBytes[0])
  result.minFilter = TextureFilter.Linear
  result.magFilter = TextureFilter.Linear
  result.wrapS = WrapMode.Repeat
  result.wrapT = WrapMode.Repeat

when isMainModule:
  let window = newWindow("OpenGL Textured Quad", ivec2(Width, Height))
  makeContextCurrent(window)
  ogl.init()

  var program = newProgram(VertShader, FragShader)
  var texture = loadTexture()

  var vbo = newBuffer(Vertices, BufferUsage.StaticDraw)
  var vao = newVertexArray()
  vao.addBuffer(vbo, [
    attr(0, 3, float32),
    attr(1, 3, float32),
    attr(2, 2, float32),
  ])

  program.setUniform("uTexture", 0'i32)
  ogl.clearColor(0.05, 0.05, 0.1, 1.0)

  window.onResize = proc() =
    let size = window.size
    if size.x > 0 and size.y > 0:
      ogl.viewport(0, 0, size.x.int, size.y.int)

  while not window.closeRequested:
    pollEvents()

    ogl.clear({ClearBit.Color})
    program.use()
    texture.bindToUnit(0)
    vao.bindVao()
    ogl.drawArrays(Primitive.Triangles, 0, Vertices.len)

    window.swapBuffers()

  destroy(vao)
  destroy(vbo)
  destroy(texture)
  destroy(program)
