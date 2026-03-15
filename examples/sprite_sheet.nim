import
  std/os,
  pixie,
  vmath,
  windy,
  ../src/ogl

const
  InitialWidth = 1280
  InitialHeight = 800
  SheetCells = 8
  SpriteDrawSize = 24.0'f32
  SpriteDensity = 850.0'f32
  MinSpriteCount = 96

  VertShader = """
#version 450 core
layout(location = 0) in vec2 aPosition;
layout(location = 1) in vec2 aUV;
out vec2 vUV;
void main() {
    gl_Position = vec4(aPosition, 0.0, 1.0);
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
  SpriteVertex = object
    position: array[2, float32]
    uv: array[2, float32]

  SpriteDrawer = object
    vertices: seq[SpriteVertex]
    viewportSize: IVec2

proc clampWindowSize(size: IVec2): IVec2 =
  ivec2(max(1'i32, size.x), max(1'i32, size.y))

proc spriteCountForSize(size: IVec2): int =
  let area = size.x.float32 * size.y.float32
  max(MinSpriteCount, int(area / SpriteDensity))

proc hash32(value: uint32): uint32 =
  result = value
  result = result xor (result shr 16)
  result *= 0x7feb352d'u32
  result = result xor (result shr 15)
  result *= 0x846ca68b'u32
  result = result xor (result shr 16)

proc random01(seed: uint32): float32 =
  (hash32(seed) and 0x00ff_ffff'u32).float32 / 16_777_215.0'f32

proc randomInt(seed: uint32, limit: int): int =
  if limit <= 0: return 0
  int(hash32(seed) mod uint32(limit + 1))

proc screenToClip(drawer: SpriteDrawer, pos: Vec2): Vec2 =
  let
    w = max(1.0'f32, drawer.viewportSize.x.float32)
    h = max(1.0'f32, drawer.viewportSize.y.float32)
  vec2(
    (pos.x / w) * 2.0'f32 - 1.0'f32,
    1.0'f32 - (pos.y / h) * 2.0'f32
  )

proc beginDraw(drawer: var SpriteDrawer, viewportSize: IVec2) =
  drawer.viewportSize = clampWindowSize(viewportSize)
  drawer.vertices.setLen(0)

proc pushVertex(drawer: var SpriteDrawer, p, tc: Vec2) =
  drawer.vertices.add(SpriteVertex(position: [p.x, p.y], uv: [tc.x, tc.y]))

proc drawQuad(drawer: var SpriteDrawer, positions: array[4, Vec2], uvs: array[4, Vec2]) =
  let cp = [
    drawer.screenToClip(positions[0]),
    drawer.screenToClip(positions[1]),
    drawer.screenToClip(positions[2]),
    drawer.screenToClip(positions[3])
  ]
  drawer.pushVertex(cp[0], uvs[0])
  drawer.pushVertex(cp[1], uvs[1])
  drawer.pushVertex(cp[2], uvs[2])
  drawer.pushVertex(cp[0], uvs[0])
  drawer.pushVertex(cp[2], uvs[2])
  drawer.pushVertex(cp[3], uvs[3])

proc drawIcon(drawer: var SpriteDrawer, icon: IVec2, pos: Vec2) =
  let
    iconSize = vec2(SpriteDrawSize, SpriteDrawSize)
    cellSize = 1.0'f32 / SheetCells.float32
    uvMin = vec2(icon.x.float32 * cellSize, icon.y.float32 * cellSize)
    uvMax = uvMin + vec2(cellSize, cellSize)
    positions = [
      pos,
      pos + vec2(iconSize.x, 0.0'f32),
      pos + iconSize,
      pos + vec2(0.0'f32, iconSize.y)
    ]
    uvs = [
      uvMin,
      vec2(uvMax.x, uvMin.y),
      uvMax,
      vec2(uvMin.x, uvMax.y)
    ]
  drawer.drawQuad(positions, uvs)

proc texturePath(): string =
  currentSourcePath().parentDir / "testSpriteSheet.png"

proc buildMipChain(image: Image): seq[Image] =
  result.add(image)
  var current = image
  while current.width > 1 or current.height > 1:
    current = current.minifyBy2()
    result.add(current)

proc loadSpriteTexture(): ogl.Texture =
  let path = texturePath()
  if not fileExists(path):
    raise newException(IOError, "Sprite sheet not found: " & path)

  let img = readImage(path)
  let mips = buildMipChain(img)
  let
    w = mips[0].width
    h = mips[0].height
    levels = mips.len

  result = newTexture2D(InternalFormat.RGBA8, w, h, levels)
  for i, mip in mips:
    var pixelBytes = newSeq[uint8](mip.width * mip.height * 4)
    for y in 0 ..< mip.height:
      let srcIdx = mip.dataIndex(0, y)
      let srcPtr = cast[ptr uint8](mip.data[srcIdx].addr)
      copyMem(addr pixelBytes[y * mip.width * 4], srcPtr, mip.width * 4)
    result.upload(i, 0, 0, mip.width, mip.height,
                  PixelFormat.RGBA, PixelType.UByte, addr pixelBytes[0])

  result.minFilter = TextureFilter.LinearMipmapLinear
  result.magFilter = TextureFilter.Linear
  result.wrapS = WrapMode.ClampToEdge
  result.wrapT = WrapMode.ClampToEdge
  result.maxAnisotropy = 8.0'f32

when isMainModule:
  let window = newWindow("OpenGL Sprite Sheet", ivec2(InitialWidth, InitialHeight))
  makeContextCurrent(window)
  ogl.init()

  var program = newProgram(VertShader, FragShader)
  var texture = loadSpriteTexture()

  var vao = newVertexArray()
  var vbo = createBuffer()

  vao.addBuffer(vbo, [
    attr(0, 2, float32),
    attr(1, 2, float32),
  ])

  program.setUniform("uTexture", 0'i32)

  ogl.enable(Capability.Blend)
  ogl.blendFunc(BlendFactor.SrcAlpha, BlendFactor.OneMinusSrcAlpha)
  ogl.clearColor(0.08, 0.08, 0.1, 1.0)

  var
    drawer: SpriteDrawer
    renderSize = clampWindowSize(window.size)

  window.onResize = proc() =
    let size = window.size
    if size.x > 0 and size.y > 0:
      ogl.viewport(0, 0, size.x.int, size.y.int)

  while not window.closeRequested:
    pollEvents()

    renderSize = clampWindowSize(window.size)
    drawer.beginDraw(renderSize)

    let
      spriteCount = spriteCountForSize(renderSize)
      maxX = max(0.0'f32, renderSize.x.float32 - SpriteDrawSize)
      maxY = max(0.0'f32, renderSize.y.float32 - SpriteDrawSize)
      baseSeed =
        uint32(renderSize.x) xor
        (uint32(renderSize.y) shl 16) xor
        0x1357_9bdf'u32

    for i in 0 ..< spriteCount:
      let
        seed = baseSeed + uint32(i) * 0x9e37_79b9'u32
        pos = vec2(
          random01(seed xor 0x68bc_21ebu32) * maxX,
          random01(seed xor 0x02e5_be93u32) * maxY
        )
        icon = ivec2(
          randomInt(seed xor 0xa5a5_1021'u32, SheetCells - 1).int32,
          randomInt(seed xor 0x1f12_4bb5'u32, SheetCells - 1).int32
        )
      drawer.drawIcon(icon, pos)

    vbo.setData(drawer.vertices, BufferUsage.StreamDraw)

    ogl.clear({ClearBit.Color})
    program.use()
    texture.bindToUnit(0)
    vao.bindVao()
    ogl.drawArrays(Primitive.Triangles, 0, drawer.vertices.len)

    window.swapBuffers()

  destroy(vao)
  destroy(vbo)
  destroy(texture)
  destroy(program)
