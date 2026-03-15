import ogl

block handleTypes:
  var tex = NoTexture
  var buf = NoBuffer
  var vao = NoVertexArray
  var prog = NoProgram
  var fb = NoFramebuffer
  var rb = NoRenderbuffer
  var samp = NoSampler
  assert tex == NoTexture
  assert buf == NoBuffer
  assert vao == NoVertexArray
  assert prog == NoProgram
  assert fb == NoFramebuffer
  assert rb == NoRenderbuffer
  assert samp == NoSampler

block enumValues:
  assert ord(InternalFormat.RGBA8) == 0x8058
  assert ord(TextureFilter.Linear) == 0x2601
  assert ord(WrapMode.Repeat) == 0x2901
  assert ord(BufferUsage.StaticDraw) == 0x88E4
  assert ord(ShaderKind.Vertex) == 0x8B31
  assert ord(ShaderKind.Fragment) == 0x8B30
  assert ord(Primitive.Triangles) == 0x0004
  assert ord(CompareFunc.Less) == 0x0201
  assert ord(Capability.DepthTest) == 0x0B71

block vertexAttribs:
  let a = attr(0, 3, float32)
  assert a.location == 0
  assert a.size == 3
  assert a.kind == AttribType.Float
  assert a.normalized == false

  let b = attr(1, 4, uint8)
  assert b.location == 1
  assert b.size == 4
  assert b.kind == AttribType.UByte

block handlePrinting:
  assert $NoTexture == "Texture(0)"
  assert $NoBuffer == "Buffer(0)"
  assert $NoProgram == "Program(0)"

echo "All tests passed."
