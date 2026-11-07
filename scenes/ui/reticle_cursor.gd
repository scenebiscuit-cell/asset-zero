class_name ReticleCursor
extends RefCounted
## A small green targeting reticle used as the mouse cursor in menus, drawn in code (no image file).

const SIZE: int = 21
const COLOR: Color = Color(0.35, 1.0, 0.45)


static func apply() -> void:
	var image: Image = Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	var c: int = floori(SIZE / 2.0)
	# Ring of radius 6.
	for y: int in SIZE:
		for x: int in SIZE:
			if absf(Vector2(x - c, y - c).length() - 6.0) < 0.6:
				image.set_pixel(x, y, COLOR)
	# Four ticks crossing the ring, with a gap in the middle so the target stays visible.
	for i: int in range(3, 10):
		image.set_pixel(c - i, c, COLOR)
		image.set_pixel(c + i, c, COLOR)
		image.set_pixel(c, c - i, COLOR)
		image.set_pixel(c, c + i, COLOR)
	image.set_pixel(c, c, COLOR)
	Input.set_custom_mouse_cursor(ImageTexture.create_from_image(image), Input.CURSOR_ARROW, Vector2(c, c))
