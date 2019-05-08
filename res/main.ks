var side = 20
var r = [100, 100, side, side]
var dragging = false

sub setup() {
    loop(false)
    rectMode(CENTER)
    size(480.0, 640.0)
}

sub draw() {
    // you can specify a color via…
    background('white') // keyword
    stroke(#FF0000)     // hex value
    fill(0, 255, 0)     // or rgb
    strokeWeight(2)
    rect(r)
}

sub mouseDown() {
    var p = [mouseX, mouseY]
    if contains(r, p) {
        dragging = true
    }
}

sub mouseDragged() {
    if dragging {
        r[1] = mouseX
        r[2] = mouseY
    }
    redraw()
}

sub mouseUp() {
    dragging = false
}
