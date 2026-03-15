import
  std/[math, os, strutils],
  vmath,
  windy,
  ../src/ogl

const
  Width = 1280
  Height = 800
  RotateScale = 0.01'f32
  ZoomScale = 0.2'f32
  MinDistance = 1.0'f32
  MaxDistance = 8.0'f32
  MinPitch = -1.45'f32
  MaxPitch = 1.45'f32

  VertShader = """
#version 450 core
layout(location = 0) in vec3 aPosition;
layout(location = 1) in vec3 aNormal;
uniform mat4 uMVP;
uniform mat4 uModel;
out vec3 vNormal;
void main() {
    gl_Position = uMVP * vec4(aPosition, 1.0);
    vNormal = normalize(mat3(uModel) * aNormal);
}
"""

  FragShader = """
#version 450 core
in vec3 vNormal;
out vec4 fragColor;
void main() {
    vec3 lightDir = normalize(vec3(0.4, 0.8, 0.5));
    float diffuse = abs(dot(normalize(vNormal), lightDir));
    float light = 0.2 + diffuse * 0.8;
    vec3 baseColor = vec3(0.88, 0.84, 0.78);
    fragColor = vec4(baseColor * light, 1.0);
}
"""

type
  ObjVertex = object
    position: array[3, float32]
    normal: array[3, float32]

  ObjMesh = object
    vertices: seq[ObjVertex]

  CameraState = object
    yaw: float32
    pitch: float32
    distance: float32

proc objPath(): string =
  currentSourcePath().parentDir / "bunny.obj"

proc mat4ToArray(m: Mat4): array[16, float32] =
  var i = 0
  for col in 0 ..< 4:
    for row in 0 ..< 4:
      result[i] = m[col, row]
      inc i

proc toFloatArray(v: Vec3): array[3, float32] =
  [v.x, v.y, v.z]

proc parseFloat32(value: string): float32 =
  parseFloat(value).float32

proc parseObjIndex(value: string, vertexCount: int): int =
  let rawIndex = parseInt(value)
  result =
    if rawIndex > 0: rawIndex - 1
    elif rawIndex < 0: vertexCount + rawIndex
    else: raise newException(IOError, "OBJ indices cannot be zero")
  if result < 0 or result >= vertexCount:
    raise newException(IOError, "OBJ face index out of range: " & value)

proc parseFaceVertex(token: string, vertexCount: int): int =
  let slash = token.find('/')
  let indexToken = if slash >= 0: token[0 ..< slash] else: token
  parseObjIndex(indexToken, vertexCount)

proc normalizeSafe(v, fallback: Vec3): Vec3 =
  if v.length() <= 0.000001'f32: fallback
  else: v.normalize()

proc loadObjMesh(path: string): ObjMesh =
  if not fileExists(path):
    raise newException(IOError, "OBJ file not found: " & path)

  var
    positions: seq[Vec3]
    triangles: seq[array[3, int]]

  for rawLine in readFile(path).splitLines():
    let line = rawLine.strip()
    if line.len == 0 or line[0] == '#':
      continue
    let parts = strutils.splitWhitespace(line)
    case parts[0]
    of "v":
      if parts.len < 4: continue
      positions.add(vec3(
        parseFloat32(parts[1]),
        parseFloat32(parts[2]),
        parseFloat32(parts[3])
      ))
    of "f":
      if parts.len < 4: continue
      var faceIndices: seq[int]
      for i in 1 ..< parts.len:
        faceIndices.add(parseFaceVertex(parts[i], positions.len))
      for i in 1 ..< faceIndices.len - 1:
        triangles.add([faceIndices[0], faceIndices[i], faceIndices[i + 1]])
    else:
      discard

  var minPos = positions[0]
  var maxPos = positions[0]
  for i in 1 ..< positions.len:
    let p = positions[i]
    minPos.x = min(minPos.x, p.x); minPos.y = min(minPos.y, p.y); minPos.z = min(minPos.z, p.z)
    maxPos.x = max(maxPos.x, p.x); maxPos.y = max(maxPos.y, p.y); maxPos.z = max(maxPos.z, p.z)

  let
    center = (minPos + maxPos) * 0.5'f32
    size = maxPos - minPos
    maxExtent = max(size.x, max(size.y, size.z))
    uniformScale = 2.0'f32 / maxExtent

  var normalizedPositions = newSeq[Vec3](positions.len)
  for i, p in positions:
    normalizedPositions[i] = (p - center) * uniformScale

  var smoothedNormals = newSeq[Vec3](normalizedPositions.len)
  for tri in triangles:
    let
      a = normalizedPositions[tri[0]]
      b = normalizedPositions[tri[1]]
      c = normalizedPositions[tri[2]]
      faceNormal = normalizeSafe((b - a).cross(c - a), vec3(0.0'f32, 1.0'f32, 0.0'f32))
    smoothedNormals[tri[0]] += faceNormal
    smoothedNormals[tri[1]] += faceNormal
    smoothedNormals[tri[2]] += faceNormal

  result.vertices = newSeq[ObjVertex](triangles.len * 3)
  var vi = 0
  for tri in triangles:
    for idx in tri:
      result.vertices[vi] = ObjVertex(
        position: normalizedPositions[idx].toFloatArray(),
        normal: normalizeSafe(smoothedNormals[idx], vec3(0.0'f32, 1.0'f32, 0.0'f32)).toFloatArray()
      )
      inc vi

proc updateCamera(camera: var CameraState, window: Window) =
  if window.buttonDown[MouseLeft]:
    let delta = window.mouseDelta
    camera.yaw -= delta.x.float32 * RotateScale
    camera.pitch = clamp(
      camera.pitch - delta.y.float32 * RotateScale,
      MinPitch, MaxPitch
    )
  let scroll = window.scrollDelta
  if scroll.y != 0.0'f32:
    camera.distance = clamp(
      camera.distance - scroll.y.float32 * ZoomScale,
      MinDistance, MaxDistance
    )

when isMainModule:
  let window = newWindow("OpenGL 4.6 DSA - Bunny Viewer", ivec2(Width, Height),
                          msaa = msaa4x)
  makeContextCurrent(window)
  ogl.init()

  let mesh = loadObjMesh(objPath())

  var program = newProgram(VertShader, FragShader)
  let mvpLoc = program.uniformLoc("uMVP")
  let modelLoc = program.uniformLoc("uModel")

  var vbo = newBuffer(mesh.vertices, BufferUsage.StaticDraw)
  var vao = newVertexArray()
  vao.addBuffer(vbo, [
    attr(0, 3, float32),
    attr(1, 3, float32),
  ])

  ogl.enable(Capability.DepthTest)
  ogl.depthFunc(CompareFunc.Less)
  ogl.enable(Capability.Multisample)
  ogl.clearColor(0.05, 0.05, 0.08, 1.0)

  var camera = CameraState(
    yaw: 0.0'f32,
    pitch: 0.15'f32,
    distance: 2.8'f32
  )

  window.onResize = proc() =
    let size = window.size
    if size.x > 0 and size.y > 0:
      ogl.viewport(0, 0, size.x.int, size.y.int)

  while not window.closeRequested:
    pollEvents()
    updateCamera(camera, window)

    let
      size = window.size
      aspect = size.x.float32 / max(1, size.y).float32
      model = mat4()
      view =
        translate(vec3(0.0'f32, 0.0'f32, -camera.distance)) *
        rotateX(camera.pitch) *
        rotateY(camera.yaw)
      proj = perspective(60.0'f32, aspect, 0.1'f32, 100.0'f32)
      mvp = proj * view * model

    var mvpArr = mat4ToArray(mvp)
    var modelArr = mat4ToArray(model)

    ogl.clear({ClearBit.Color, ClearBit.Depth})
    program.use()
    program.setUniformMat4(mvpLoc, mvpArr)
    program.setUniformMat4(modelLoc, modelArr)
    vao.bindVao()
    ogl.drawArrays(Primitive.Triangles, 0, mesh.vertices.len)

    window.swapBuffers()

  destroy(vao)
  destroy(vbo)
  destroy(program)
