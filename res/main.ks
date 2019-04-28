
sub setup() {
    noLoop()
    size(480.0, 640.0)
}

sub draw() {
    background('white')
    line([0,0], [mouseX, mouseY])
}

sub mouseDragged() {
    redraw()
}
