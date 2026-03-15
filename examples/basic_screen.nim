import std/math
import windy
import ../src/ogl

const
  Width = 1280
  Height = 800

when isMainModule:
  let window = newWindow("OpenGL Color Cycle", ivec2(Width, Height), vsync = true)
  makeContextCurrent(window)
  ogl.init()

  var timeAcc = 0.0

  while not window.closeRequested:
    pollEvents()
    timeAcc += 0.016

    let
      r = (sin(timeAcc * 0.6) * 0.5 + 0.5).float32
      g = (sin(timeAcc * 0.6 + 2.094) * 0.5 + 0.5).float32
      b = (sin(timeAcc * 0.6 + 4.188) * 0.5 + 0.5).float32

    ogl.clearColor(r, g, b, 1.0)
    ogl.clear({ClearBit.Color})
    window.swapBuffers()
