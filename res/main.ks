
sub setup() {
    loop(false)
    rectMode(CENTER)
    size(480.0, 640.0)
}

sub draw() {
    background('white')
    rect(mouseX, mouseY, 20, 20)
}

sub mouseDragged() {
    redraw()
}
