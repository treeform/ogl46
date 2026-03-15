## ogl - A safe, DSA-only OpenGL 4.5+ wrapper for Nim
##
## Imports the standard Nim `opengl` bindings internally but only exposes
## the Direct State Access (DSA) subset along with type-safe enums and
## distinct handle types. The legacy bind-to-edit API is completely hidden.

import opengl

# ==========================================================================
# Error type
# ==========================================================================

type OglError* = object of CatchableError

# ==========================================================================
# Handle types
# ==========================================================================

type
  Texture* = distinct GLuint
  Buffer* = distinct GLuint
  VertexArray* = distinct GLuint
  Shader* = distinct GLuint
  Program* = distinct GLuint
  Framebuffer* = distinct GLuint
  Renderbuffer* = distinct GLuint
  Sampler* = distinct GLuint
  UniformLoc* = distinct GLint

proc `==`*(a, b: Texture): bool {.borrow.}
proc `==`*(a, b: Buffer): bool {.borrow.}
proc `==`*(a, b: VertexArray): bool {.borrow.}
proc `==`*(a, b: Shader): bool {.borrow.}
proc `==`*(a, b: Program): bool {.borrow.}
proc `==`*(a, b: Framebuffer): bool {.borrow.}
proc `==`*(a, b: Renderbuffer): bool {.borrow.}
proc `==`*(a, b: Sampler): bool {.borrow.}
proc `==`*(a, b: UniformLoc): bool {.borrow.}

proc `$`*(x: Texture): string = "Texture(" & $GLuint(x) & ")"
proc `$`*(x: Buffer): string = "Buffer(" & $GLuint(x) & ")"
proc `$`*(x: VertexArray): string = "VertexArray(" & $GLuint(x) & ")"
proc `$`*(x: Shader): string = "Shader(" & $GLuint(x) & ")"
proc `$`*(x: Program): string = "Program(" & $GLuint(x) & ")"
proc `$`*(x: Framebuffer): string = "Framebuffer(" & $GLuint(x) & ")"
proc `$`*(x: Renderbuffer): string = "Renderbuffer(" & $GLuint(x) & ")"
proc `$`*(x: Sampler): string = "Sampler(" & $GLuint(x) & ")"

const
  NoTexture* = Texture(0)
  NoBuffer* = Buffer(0)
  NoVertexArray* = VertexArray(0)
  NoProgram* = Program(0)
  NoFramebuffer* = Framebuffer(0)
  NoRenderbuffer* = Renderbuffer(0)
  NoSampler* = Sampler(0)
  InvalidUniform* = UniformLoc(-1)

# ==========================================================================
# Enums
# ==========================================================================

type
  InternalFormat* {.pure.} = enum
    R8 = 0x8229
    RG8 = 0x822B
    RGB8 = 0x8051
    RGBA8 = 0x8058
    SRGB8 = 0x8C41
    SRGBA8 = 0x8C43
    R16F = 0x822D
    RG16F = 0x822F
    RGB16F = 0x881B
    RGBA16F = 0x881A
    R32F = 0x822E
    RG32F = 0x8230
    RGB32F = 0x8815
    RGBA32F = 0x8814
    R8I = 0x8231
    R8UI = 0x8232
    R16I = 0x8233
    R16UI = 0x8234
    R32I = 0x8235
    R32UI = 0x8236
    Depth16 = 0x81A5
    Depth24 = 0x81A6
    Depth32F = 0x8CAC
    Depth24Stencil8 = 0x88F0
    Depth32FStencil8 = 0x8CAD

  PixelFormat* {.pure.} = enum
    Red = 0x1903
    RG = 0x8227
    RGB = 0x1907
    BGR = 0x80E0
    RGBA = 0x1908
    BGRA = 0x80E1
    DepthComponent = 0x1902
    StencilIndex = 0x1901
    DepthStencil = 0x84F9

  PixelType* {.pure.} = enum
    Byte = 0x1400
    UByte = 0x1401
    Short = 0x1402
    UShort = 0x1403
    Int = 0x1404
    UInt = 0x1405
    HalfFloat = 0x140B
    Float = 0x1406

  TextureFilter* {.pure.} = enum
    Nearest = 0x2600
    Linear = 0x2601
    NearestMipmapNearest = 0x2700
    LinearMipmapNearest = 0x2701
    NearestMipmapLinear = 0x2702
    LinearMipmapLinear = 0x2703

  WrapMode* {.pure.} = enum
    ClampToBorder = 0x812D
    ClampToEdge = 0x812F
    Repeat = 0x2901
    MirroredRepeat = 0x8370
    MirrorClampToEdge = 0x8743

  BufferUsage* {.pure.} = enum
    StreamDraw = 0x88E0
    StreamRead = 0x88E1
    StreamCopy = 0x88E2
    StaticDraw = 0x88E4
    StaticRead = 0x88E5
    StaticCopy = 0x88E6
    DynamicDraw = 0x88E8
    DynamicRead = 0x88E9
    DynamicCopy = 0x88EA

  BufferFlag* {.pure.} = enum
    MapRead
    MapWrite
    MapPersistent
    MapCoherent
    DynamicStorage
    ClientStorage

  ShaderKind* {.pure.} = enum
    Fragment = 0x8B30
    Vertex = 0x8B31
    Geometry = 0x8DD9
    TessEvaluation = 0x8E87
    TessControl = 0x8E88
    Compute = 0x91B9

  Primitive* {.pure.} = enum
    Points = 0x0000
    Lines = 0x0001
    LineLoop = 0x0002
    LineStrip = 0x0003
    Triangles = 0x0004
    TriangleStrip = 0x0005
    TriangleFan = 0x0006
    Patches = 0x000E

  IndexType* {.pure.} = enum
    UByte = 0x1401
    UShort = 0x1403
    UInt = 0x1405

  Capability* {.pure.} = enum
    CullFace = 0x0B44
    DepthTest = 0x0B71
    StencilTest = 0x0B90
    Blend = 0x0BE2
    ScissorTest = 0x0C11
    Multisample = 0x809D
    ProgramPointSize = 0x8642
    SeamlessCubeMap = 0x884F
    FramebufferSRGB = 0x8DB9

  BlendFactor* {.pure.} = enum
    Zero = 0
    One = 1
    SrcColor = 0x0300
    OneMinusSrcColor = 0x0301
    SrcAlpha = 0x0302
    OneMinusSrcAlpha = 0x0303
    DstAlpha = 0x0304
    OneMinusDstAlpha = 0x0305
    DstColor = 0x0306
    OneMinusDstColor = 0x0307
    ConstantColor = 0x8001
    OneMinusConstantColor = 0x8002
    ConstantAlpha = 0x8003
    OneMinusConstantAlpha = 0x8004

  BlendOp* {.pure.} = enum
    Add = 0x8006
    Min = 0x8007
    Max = 0x8008
    Subtract = 0x800A
    ReverseSubtract = 0x800B

  CompareFunc* {.pure.} = enum
    Never = 0x0200
    Less = 0x0201
    Equal = 0x0202
    LessOrEqual = 0x0203
    Greater = 0x0204
    NotEqual = 0x0205
    GreaterOrEqual = 0x0206
    Always = 0x0207

  Face* {.pure.} = enum
    Front = 0x0404
    Back = 0x0405
    FrontAndBack = 0x0408

  Winding* {.pure.} = enum
    CW = 0x0900
    CCW = 0x0901

  FillMode* {.pure.} = enum
    Point = 0x1B00
    Line = 0x1B01
    Fill = 0x1B02

  ClearBit* {.pure.} = enum
    Depth
    Stencil
    Color

  AttribType* {.pure.} = enum
    Byte = 0x1400
    UByte = 0x1401
    Short = 0x1402
    UShort = 0x1403
    Int = 0x1404
    UInt = 0x1405
    HalfFloat = 0x140B
    Float = 0x1406
    Double = 0x140A

  FbAttachment* {.pure.} = enum
    DepthStencil = 0x821A
    Color0 = 0x8CE0
    Color1 = 0x8CE1
    Color2 = 0x8CE2
    Color3 = 0x8CE3
    Color4 = 0x8CE4
    Color5 = 0x8CE5
    Color6 = 0x8CE6
    Color7 = 0x8CE7
    Depth = 0x8D00
    Stencil = 0x8D20

  FbStatus* {.pure.} = enum
    Undefined = 0x8219
    Complete = 0x8CD5
    IncompleteAttachment = 0x8CD6
    IncompleteMissingAttachment = 0x8CD7
    IncompleteDrawBuffer = 0x8CDB
    IncompleteReadBuffer = 0x8CDC
    Unsupported = 0x8CDD
    IncompleteMultisample = 0x8D56
    IncompleteLayerTargets = 0x8DA8

# ==========================================================================
# Vertex attribute descriptor
# ==========================================================================

type
  VertexAttrib* = object
    location*: uint32
    size*: int32
    kind*: AttribType
    normalized*: bool

proc componentSize(kind: AttribType): int =
  case kind
  of AttribType.Byte, AttribType.UByte: 1
  of AttribType.Short, AttribType.UShort, AttribType.HalfFloat: 2
  of AttribType.Int, AttribType.UInt, AttribType.Float: 4
  of AttribType.Double: 8

proc attr*(location, size: int, kind: AttribType, normalized = false): VertexAttrib =
  VertexAttrib(location: location.uint32, size: size.int32, kind: kind, normalized: normalized)

proc attr*(location, size: int, T: typedesc[float32]): VertexAttrib = attr(location, size, AttribType.Float)
proc attr*(location, size: int, T: typedesc[float64]): VertexAttrib = attr(location, size, AttribType.Double)
proc attr*(location, size: int, T: typedesc[int32]): VertexAttrib = attr(location, size, AttribType.Int)
proc attr*(location, size: int, T: typedesc[uint32]): VertexAttrib = attr(location, size, AttribType.UInt)
proc attr*(location, size: int, T: typedesc[int16]): VertexAttrib = attr(location, size, AttribType.Short)
proc attr*(location, size: int, T: typedesc[uint16]): VertexAttrib = attr(location, size, AttribType.UShort)
proc attr*(location, size: int, T: typedesc[int8]): VertexAttrib = attr(location, size, AttribType.Byte)
proc attr*(location, size: int, T: typedesc[uint8]): VertexAttrib = attr(location, size, AttribType.UByte)

# ==========================================================================
# Private helpers
# ==========================================================================

proc toClearMask(bits: set[ClearBit]): GLbitfield =
  if ClearBit.Color in bits: result = result or GL_COLOR_BUFFER_BIT
  if ClearBit.Depth in bits: result = result or GL_DEPTH_BUFFER_BIT
  if ClearBit.Stencil in bits: result = result or GL_STENCIL_BUFFER_BIT

proc toStorageFlags(flags: set[BufferFlag]): GLbitfield =
  if BufferFlag.MapRead in flags: result = result or GLbitfield(0x0001)
  if BufferFlag.MapWrite in flags: result = result or GLbitfield(0x0002)
  if BufferFlag.MapPersistent in flags: result = result or GLbitfield(0x0040)
  if BufferFlag.MapCoherent in flags: result = result or GLbitfield(0x0080)
  if BufferFlag.DynamicStorage in flags: result = result or GLbitfield(0x0100)
  if BufferFlag.ClientStorage in flags: result = result or GLbitfield(0x0200)

# ==========================================================================
# Initialization
# ==========================================================================

proc init*() =
  ## Call after creating an OpenGL 4.5+ context to load all GL function pointers.
  opengl.loadExtensions()

proc version*(): string =
  $cast[cstring](glGetString(GL_VERSION))

proc renderer*(): string =
  $cast[cstring](glGetString(GL_RENDERER))

# ==========================================================================
# Textures (DSA)
# ==========================================================================

proc createTexture2D*(): Texture =
  var id: GLuint
  glCreateTextures(GL_TEXTURE_2D, 1, addr id)
  Texture(id)

proc newTexture2D*(format: InternalFormat, width, height: int, levels = 1): Texture =
  result = createTexture2D()
  glTextureStorage2D(GLuint(result), levels.GLsizei, ord(format).GLenum,
                     width.GLsizei, height.GLsizei)

proc storage2D*(tex: Texture, levels: int, format: InternalFormat, width, height: int) =
  glTextureStorage2D(GLuint(tex), levels.GLsizei, ord(format).GLenum,
                     width.GLsizei, height.GLsizei)

proc upload*(tex: Texture, level: int, x, y, width, height: int,
             format: PixelFormat, pixelType: PixelType, data: pointer) =
  glTextureSubImage2D(GLuint(tex), level.GLint, x.GLint, y.GLint,
                      width.GLsizei, height.GLsizei,
                      ord(format).GLenum, ord(pixelType).GLenum, data)

proc upload*(tex: Texture, width, height: int,
             format: PixelFormat, pixelType: PixelType, data: pointer) =
  tex.upload(0, 0, 0, width, height, format, pixelType, data)

proc `minFilter=`*(tex: Texture, filter: TextureFilter) =
  glTextureParameteri(GLuint(tex), GL_TEXTURE_MIN_FILTER, ord(filter).GLint)

proc `magFilter=`*(tex: Texture, filter: TextureFilter) =
  glTextureParameteri(GLuint(tex), GL_TEXTURE_MAG_FILTER, ord(filter).GLint)

proc `wrapS=`*(tex: Texture, mode: WrapMode) =
  glTextureParameteri(GLuint(tex), GL_TEXTURE_WRAP_S, ord(mode).GLint)

proc `wrapT=`*(tex: Texture, mode: WrapMode) =
  glTextureParameteri(GLuint(tex), GL_TEXTURE_WRAP_T, ord(mode).GLint)

proc `wrapR=`*(tex: Texture, mode: WrapMode) =
  glTextureParameteri(GLuint(tex), GL_TEXTURE_WRAP_R, ord(mode).GLint)

proc `maxAnisotropy=`*(tex: Texture, value: float32) =
  glTextureParameterf(GLuint(tex), 0x84FE.GLenum, value)

proc generateMipmaps*(tex: Texture) =
  glGenerateTextureMipmap(GLuint(tex))

proc bindToUnit*(tex: Texture, unit: int) =
  glBindTextureUnit(unit.GLuint, GLuint(tex))

proc destroy*(tex: var Texture) =
  if GLuint(tex) != 0:
    var id = GLuint(tex)
    glDeleteTextures(1, addr id)
    tex = NoTexture

# ==========================================================================
# Buffers (DSA)
# ==========================================================================

proc createBuffer*(): Buffer =
  var id: GLuint
  glCreateBuffers(1, addr id)
  Buffer(id)

proc newBuffer*(size: int, data: pointer, usage: BufferUsage): Buffer =
  result = createBuffer()
  glNamedBufferData(GLuint(result), size.GLsizeiptr, data, ord(usage).GLenum)

proc newBuffer*[T](data: openArray[T], usage: BufferUsage): Buffer =
  if data.len > 0:
    newBuffer(data.len * sizeof(T), unsafeAddr data[0], usage)
  else:
    newBuffer(0, nil, usage)

proc newBuffer*(size: int, usage: BufferUsage): Buffer =
  newBuffer(size, nil, usage)

proc setData*(buf: Buffer, size: int, data: pointer, usage: BufferUsage) =
  glNamedBufferData(GLuint(buf), size.GLsizeiptr, data, ord(usage).GLenum)

proc setData*[T](buf: Buffer, data: openArray[T], usage: BufferUsage) =
  if data.len > 0:
    glNamedBufferData(GLuint(buf), GLsizeiptr(data.len * sizeof(T)),
                      unsafeAddr data[0], ord(usage).GLenum)
  else:
    glNamedBufferData(GLuint(buf), 0.GLsizeiptr, nil, ord(usage).GLenum)

proc setSubData*(buf: Buffer, offset, size: int, data: pointer) =
  glNamedBufferSubData(GLuint(buf), offset.GLintptr, size.GLsizeiptr, data)

proc setSubData*[T](buf: Buffer, offset: int, data: openArray[T]) =
  if data.len > 0:
    glNamedBufferSubData(GLuint(buf), offset.GLintptr,
                         GLsizeiptr(data.len * sizeof(T)), unsafeAddr data[0])

proc initStorage*(buf: Buffer, size: int, data: pointer, flags: set[BufferFlag]) =
  glNamedBufferStorage(GLuint(buf), size.GLsizeiptr, data, toStorageFlags(flags))

proc initStorage*[T](buf: Buffer, data: openArray[T], flags: set[BufferFlag]) =
  if data.len > 0:
    buf.initStorage(data.len * sizeof(T), unsafeAddr data[0], flags)
  else:
    buf.initStorage(0, nil, flags)

proc destroy*(buf: var Buffer) =
  if GLuint(buf) != 0:
    var id = GLuint(buf)
    glDeleteBuffers(1, addr id)
    buf = NoBuffer

# ==========================================================================
# Vertex Arrays (DSA)
# ==========================================================================

proc newVertexArray*(): VertexArray =
  var id: GLuint
  glCreateVertexArrays(1, addr id)
  VertexArray(id)

proc addBuffer*(vao: VertexArray, buf: Buffer, attribs: openArray[VertexAttrib],
                binding = 0) =
  var stride = 0
  for a in attribs:
    stride += a.size.int * componentSize(a.kind)

  glVertexArrayVertexBuffer(GLuint(vao), binding.GLuint, GLuint(buf),
                            0, stride.GLsizei)

  var offset = 0'u32
  for a in attribs:
    glEnableVertexArrayAttrib(GLuint(vao), a.location)
    glVertexArrayAttribFormat(GLuint(vao), a.location, a.size,
                              ord(a.kind).GLenum,
                              if a.normalized: GL_TRUE else: GL_FALSE,
                              offset)
    glVertexArrayAttribBinding(GLuint(vao), a.location, binding.GLuint)
    offset += uint32(a.size.int * componentSize(a.kind))

proc setElementBuffer*(vao: VertexArray, buf: Buffer) =
  glVertexArrayElementBuffer(GLuint(vao), GLuint(buf))

proc enableAttrib*(vao: VertexArray, location: int) =
  glEnableVertexArrayAttrib(GLuint(vao), location.GLuint)

proc disableAttrib*(vao: VertexArray, location: int) =
  glDisableVertexArrayAttrib(GLuint(vao), location.GLuint)

proc bindVao*(vao: VertexArray) =
  glBindVertexArray(GLuint(vao))

proc unbindVao*() =
  glBindVertexArray(0)

proc destroy*(vao: var VertexArray) =
  if GLuint(vao) != 0:
    var id = GLuint(vao)
    glDeleteVertexArrays(1, addr id)
    vao = NoVertexArray

# ==========================================================================
# Shaders
# ==========================================================================

proc newShader*(kind: ShaderKind, source: string): Shader =
  let id = glCreateShader(ord(kind).GLenum)
  var src = source.cstring
  var length = source.len.GLint
  glShaderSource(id, 1, cast[cstringArray](addr src), addr length)
  glCompileShader(id)

  var status: GLint
  glGetShaderiv(id, GL_COMPILE_STATUS, addr status)
  if status == 0:
    var logLen: GLint
    glGetShaderiv(id, GL_INFO_LOG_LENGTH, addr logLen)
    var log = newString(logLen)
    glGetShaderInfoLog(id, logLen, addr logLen, log.cstring)
    glDeleteShader(id)
    raise newException(OglError, "Shader compilation failed:\n" & log)

  Shader(id)

proc destroy*(shader: var Shader) =
  if GLuint(shader) != 0:
    glDeleteShader(GLuint(shader))
    shader = Shader(0)

# ==========================================================================
# Programs
# ==========================================================================

proc newProgram*(shaders: varargs[Shader]): Program =
  let id = glCreateProgram()
  for s in shaders:
    glAttachShader(id, GLuint(s))
  glLinkProgram(id)
  for s in shaders:
    glDetachShader(id, GLuint(s))

  var status: GLint
  glGetProgramiv(id, GL_LINK_STATUS, addr status)
  if status == 0:
    var logLen: GLint
    glGetProgramiv(id, GL_INFO_LOG_LENGTH, addr logLen)
    var log = newString(logLen)
    glGetProgramInfoLog(id, logLen, addr logLen, log.cstring)
    glDeleteProgram(id)
    raise newException(OglError, "Program linking failed:\n" & log)

  Program(id)

proc newProgram*(vertSource, fragSource: string): Program =
  ## Convenience: compiles both shaders and links them into a program.
  let vs = newShader(ShaderKind.Vertex, vertSource)
  let fs = newShader(ShaderKind.Fragment, fragSource)
  try:
    result = newProgram(vs, fs)
  finally:
    glDeleteShader(GLuint(vs))
    glDeleteShader(GLuint(fs))

proc use*(prog: Program) =
  glUseProgram(GLuint(prog))

proc uniformLoc*(prog: Program, name: string): UniformLoc =
  UniformLoc(glGetUniformLocation(GLuint(prog), name.cstring))

# DSA uniform setters (glProgramUniform*) -- no need to bind the program first.

proc setUniform*(prog: Program, loc: UniformLoc, value: float32) =
  glProgramUniform1f(GLuint(prog), GLint(loc), value)

proc setUniform*(prog: Program, loc: UniformLoc, x, y: float32) =
  glProgramUniform2f(GLuint(prog), GLint(loc), x, y)

proc setUniform*(prog: Program, loc: UniformLoc, x, y, z: float32) =
  glProgramUniform3f(GLuint(prog), GLint(loc), x, y, z)

proc setUniform*(prog: Program, loc: UniformLoc, x, y, z, w: float32) =
  glProgramUniform4f(GLuint(prog), GLint(loc), x, y, z, w)

proc setUniform*(prog: Program, loc: UniformLoc, value: int32) =
  glProgramUniform1i(GLuint(prog), GLint(loc), value)

proc setUniform*(prog: Program, loc: UniformLoc, x, y: int32) =
  glProgramUniform2i(GLuint(prog), GLint(loc), x, y)

proc setUniform*(prog: Program, loc: UniformLoc, x, y, z: int32) =
  glProgramUniform3i(GLuint(prog), GLint(loc), x, y, z)

proc setUniform*(prog: Program, loc: UniformLoc, x, y, z, w: int32) =
  glProgramUniform4i(GLuint(prog), GLint(loc), x, y, z, w)

proc setUniformMat4*(prog: Program, loc: UniformLoc, mat: ptr float32,
                     transpose = false) =
  glProgramUniformMatrix4fv(GLuint(prog), GLint(loc), 1,
                            if transpose: GL_TRUE else: GL_FALSE, mat)

proc setUniformMat4*(prog: Program, loc: UniformLoc, mat: var array[16, float32],
                     transpose = false) =
  setUniformMat4(prog, loc, addr mat[0], transpose)

proc setUniform*(prog: Program, name: string, value: float32) =
  prog.setUniform(prog.uniformLoc(name), value)

proc setUniform*(prog: Program, name: string, x, y: float32) =
  prog.setUniform(prog.uniformLoc(name), x, y)

proc setUniform*(prog: Program, name: string, x, y, z: float32) =
  prog.setUniform(prog.uniformLoc(name), x, y, z)

proc setUniform*(prog: Program, name: string, x, y, z, w: float32) =
  prog.setUniform(prog.uniformLoc(name), x, y, z, w)

proc setUniform*(prog: Program, name: string, value: int32) =
  prog.setUniform(prog.uniformLoc(name), value)

proc destroy*(prog: var Program) =
  if GLuint(prog) != 0:
    glDeleteProgram(GLuint(prog))
    prog = NoProgram

# ==========================================================================
# Framebuffers (DSA)
# ==========================================================================

proc newFramebuffer*(): Framebuffer =
  var id: GLuint
  glCreateFramebuffers(1, addr id)
  Framebuffer(id)

proc attachTexture*(fb: Framebuffer, attachment: FbAttachment,
                    tex: Texture, level = 0) =
  glNamedFramebufferTexture(GLuint(fb), ord(attachment).GLenum,
                            GLuint(tex), level.GLint)

proc attachRenderbuffer*(fb: Framebuffer, attachment: FbAttachment,
                         rb: Renderbuffer) =
  glNamedFramebufferRenderbuffer(GLuint(fb), ord(attachment).GLenum,
                                 GL_RENDERBUFFER, GLuint(rb))

proc setDrawBuffers*(fb: Framebuffer, attachments: openArray[FbAttachment]) =
  var bufs: seq[GLenum]
  for a in attachments:
    bufs.add(ord(a).GLenum)
  if bufs.len > 0:
    glNamedFramebufferDrawBuffers(GLuint(fb), bufs.len.GLsizei, addr bufs[0])

proc checkStatus*(fb: Framebuffer): FbStatus =
  FbStatus(glCheckNamedFramebufferStatus(GLuint(fb), GL_FRAMEBUFFER).int)

proc bindFb*(fb: Framebuffer) =
  glBindFramebuffer(GL_FRAMEBUFFER, GLuint(fb))

proc unbindFb*() =
  glBindFramebuffer(GL_FRAMEBUFFER, 0)

proc destroy*(fb: var Framebuffer) =
  if GLuint(fb) != 0:
    var id = GLuint(fb)
    glDeleteFramebuffers(1, addr id)
    fb = NoFramebuffer

# ==========================================================================
# Renderbuffers (DSA)
# ==========================================================================

proc newRenderbuffer*(format: InternalFormat, width, height: int): Renderbuffer =
  var id: GLuint
  glCreateRenderbuffers(1, addr id)
  glNamedRenderbufferStorage(id, ord(format).GLenum, width.GLsizei, height.GLsizei)
  Renderbuffer(id)

proc newRenderbufferMultisample*(samples: int, format: InternalFormat,
                                 width, height: int): Renderbuffer =
  var id: GLuint
  glCreateRenderbuffers(1, addr id)
  glNamedRenderbufferStorageMultisample(id, samples.GLsizei, ord(format).GLenum,
                                        width.GLsizei, height.GLsizei)
  Renderbuffer(id)

proc destroy*(rb: var Renderbuffer) =
  if GLuint(rb) != 0:
    var id = GLuint(rb)
    glDeleteRenderbuffers(1, addr id)
    rb = NoRenderbuffer

# ==========================================================================
# Samplers (DSA)
# ==========================================================================

proc newSampler*(): Sampler =
  var id: GLuint
  glCreateSamplers(1, addr id)
  Sampler(id)

proc `minFilter=`*(s: Sampler, filter: TextureFilter) =
  glSamplerParameteri(GLuint(s), GL_TEXTURE_MIN_FILTER, ord(filter).GLint)

proc `magFilter=`*(s: Sampler, filter: TextureFilter) =
  glSamplerParameteri(GLuint(s), GL_TEXTURE_MAG_FILTER, ord(filter).GLint)

proc `wrapS=`*(s: Sampler, mode: WrapMode) =
  glSamplerParameteri(GLuint(s), GL_TEXTURE_WRAP_S, ord(mode).GLint)

proc `wrapT=`*(s: Sampler, mode: WrapMode) =
  glSamplerParameteri(GLuint(s), GL_TEXTURE_WRAP_T, ord(mode).GLint)

proc `wrapR=`*(s: Sampler, mode: WrapMode) =
  glSamplerParameteri(GLuint(s), GL_TEXTURE_WRAP_R, ord(mode).GLint)

proc `maxAnisotropy=`*(s: Sampler, value: float32) =
  glSamplerParameterf(GLuint(s), 0x84FE.GLenum, value)

proc bindToUnit*(s: Sampler, unit: int) =
  glBindSampler(unit.GLuint, GLuint(s))

proc destroy*(s: var Sampler) =
  if GLuint(s) != 0:
    var id = GLuint(s)
    glDeleteSamplers(1, addr id)
    s = NoSampler

# ==========================================================================
# Global state (the minimal set that has no DSA equivalent)
# ==========================================================================

proc viewport*(x, y, width, height: int) =
  glViewport(x.GLint, y.GLint, width.GLsizei, height.GLsizei)

proc scissor*(x, y, width, height: int) =
  glScissor(x.GLint, y.GLint, width.GLsizei, height.GLsizei)

proc clearColor*(r, g, b, a: float32) =
  glClearColor(r, g, b, a)

proc clearDepth*(depth: float64) =
  glClearDepth(depth)

proc clearStencil*(value: int32) =
  glClearStencil(value)

proc clear*(bits: set[ClearBit]) =
  glClear(toClearMask(bits))

proc enable*(cap: Capability) =
  glEnable(ord(cap).GLenum)

proc disable*(cap: Capability) =
  glDisable(ord(cap).GLenum)

proc blendFunc*(src, dst: BlendFactor) =
  glBlendFunc(ord(src).GLenum, ord(dst).GLenum)

proc blendFuncSeparate*(srcRGB, dstRGB, srcAlpha, dstAlpha: BlendFactor) =
  glBlendFuncSeparate(ord(srcRGB).GLenum, ord(dstRGB).GLenum,
                      ord(srcAlpha).GLenum, ord(dstAlpha).GLenum)

proc blendEquation*(op: BlendOp) =
  glBlendEquation(ord(op).GLenum)

proc blendEquationSeparate*(rgb, alpha: BlendOp) =
  glBlendEquationSeparate(ord(rgb).GLenum, ord(alpha).GLenum)

proc depthFunc*(f: CompareFunc) =
  glDepthFunc(ord(f).GLenum)

proc depthMask*(write: bool) =
  glDepthMask(if write: GL_TRUE else: GL_FALSE)

proc stencilFunc*(f: CompareFunc, reference: int32, mask: uint32) =
  glStencilFunc(ord(f).GLenum, reference.GLint, mask.GLuint)

proc stencilMask*(mask: uint32) =
  glStencilMask(mask.GLuint)

proc cullFace*(face: Face) =
  glCullFace(ord(face).GLenum)

proc frontFace*(winding: Winding) =
  glFrontFace(ord(winding).GLenum)

proc polygonMode*(face: Face, mode: FillMode) =
  glPolygonMode(ord(face).GLenum, ord(mode).GLenum)

proc lineWidth*(width: float32) =
  glLineWidth(width)

proc pointSize*(size: float32) =
  glPointSize(size)

proc colorMask*(r, g, b, a: bool) =
  glColorMask(r.GLboolean, g.GLboolean, b.GLboolean, a.GLboolean)

# ==========================================================================
# Draw commands
# ==========================================================================

proc drawArrays*(mode: Primitive, first, count: int) =
  glDrawArrays(ord(mode).GLenum, first.GLint, count.GLsizei)

proc drawElements*(mode: Primitive, count: int, indexType: IndexType,
                   offset = 0) =
  glDrawElements(ord(mode).GLenum, count.GLsizei, ord(indexType).GLenum,
                 cast[pointer](offset))

proc drawArraysInstanced*(mode: Primitive, first, count, instances: int) =
  glDrawArraysInstanced(ord(mode).GLenum, first.GLint, count.GLsizei,
                        instances.GLsizei)

proc drawElementsInstanced*(mode: Primitive, count: int, indexType: IndexType,
                            instances: int, offset = 0) =
  glDrawElementsInstanced(ord(mode).GLenum, count.GLsizei,
                          ord(indexType).GLenum, cast[pointer](offset),
                          instances.GLsizei)
