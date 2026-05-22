class_name PixelCanvas
extends RefCounted

const BAYER_4X4: Array[float] = [
	 0.0/16.0,  8.0/16.0,  2.0/16.0, 10.0/16.0,
	12.0/16.0,  4.0/16.0, 14.0/16.0,  6.0/16.0,
	 3.0/16.0, 11.0/16.0,  1.0/16.0,  9.0/16.0,
	15.0/16.0,  7.0/16.0, 13.0/16.0,  5.0/16.0,
]

var image: Image
var width: int
var height: int

func _init(w: int, h: int) -> void:
	width = w
	height = h
	image = Image.create_empty(w, h, false, Image.FORMAT_RGBA8)

func clear(color: Color = Color(0, 0, 0, 0)) -> void:
	image.fill(color)

func set_px(x: int, y: int, color: Color) -> void:
	if x < 0 or x >= width or y < 0 or y >= height:
		return
	image.set_pixel(x, y, color)

func fill_rect(x: int, y: int, w: int, h: int, color: Color) -> void:
	for py in range(y, y + h):
		for px in range(x, x + w):
			set_px(px, py, color)

func outline_rect(x: int, y: int, w: int, h: int, color: Color) -> void:
	for px in range(x, x + w):
		set_px(px, y, color)
		set_px(px, y + h - 1, color)
	for py in range(y, y + h):
		set_px(x, py, color)
		set_px(x + w - 1, py, color)

func line(x0: int, y0: int, x1: int, y1: int, color: Color) -> void:
	var dx: int = absi(x1 - x0)
	var dy: int = -absi(y1 - y0)
	var sx: int = 1 if x0 < x1 else -1
	var sy: int = 1 if y0 < y1 else -1
	var err: int = dx + dy
	while true:
		set_px(x0, y0, color)
		if x0 == x1 and y0 == y1:
			break
		var e2: int = 2 * err
		if e2 >= dy:
			err += dy
			x0 += sx
		if e2 <= dx:
			err += dx
			y0 += sy

func dither_fill(x: int, y: int, w: int, h: int, color: Color, threshold: float) -> void:
	# Bayer 4x4 ordered dither. Pixels with bayer value < threshold are drawn.
	threshold = clampf(threshold, 0.0, 1.0)
	for py in range(y, y + h):
		for px in range(x, x + w):
			var bx: int = posmod(px, 4)
			var by: int = posmod(py, 4)
			if BAYER_4X4[by * 4 + bx] < threshold:
				set_px(px, py, color)

func vgradient(x: int, y: int, w: int, h: int, top: Color, bottom: Color, steps: int = 4) -> void:
	# Pixel-art vertical gradient via dither bands.
	for i in range(steps):
		var band_y: int = y + int(float(i) / float(steps) * float(h))
		var band_h: int = int(ceilf(float(h) / float(steps)))
		var t: float = float(i) / float(maxi(steps - 1, 1))
		var c: Color = top.lerp(bottom, t)
		fill_rect(x, band_y, w, band_h, c)

func texture() -> ImageTexture:
	return ImageTexture.create_from_image(image)
