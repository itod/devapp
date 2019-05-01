var mode = CENTER
var drag = false
var side = 20.0
var loc = [100.0, 100.0]
var offset = [0.0, 0.0]

sub setup() {
    loop(false)
    shapeMode(mode)
    size(480.0, 640.0)
}

sub draw() {
    background('white')
    stroke('green')
    rect(loc[1], loc[2], side, side)
}

sub mouseDown() {
    var r = [loc[1], loc[2], side, side]
    var p = [mouseX, mouseY]
    drag = rectContainsPoint(r, p, mode)
    if drag {
        offset = [mouseX - loc[1], mouseY - loc[2]]
    }
    redraw()
}

sub mouseUp() {
    drag = false
}

sub mouseDragged() {
    if drag {
        loc[1] = mouseX - offset[1]
        loc[2] = mouseY - offset[2]
    }
    redraw()
}
