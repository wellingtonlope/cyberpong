extends GutTest

var FONT: Font = ThemeDB.fallback_font

func test_fit_font_size_shrinks_until_the_text_fits() -> void:
	var wide := FONT.get_string_size("CyberPong Settings", HORIZONTAL_ALIGNMENT_LEFT, -1, 24).x
	var fitted: int = UiDraw.fit_font_size(FONT, "CyberPong Settings", 24, 8, wide)

	assert_eq(fitted, 24)
	assert_lte(
		FONT.get_string_size("CyberPong Settings", HORIZONTAL_ALIGNMENT_LEFT, -1, fitted).x,
		wide
	)

func test_fit_font_size_never_goes_below_the_minimum() -> void:
	assert_eq(UiDraw.fit_font_size(FONT, "CyberPong Settings", 24, 8, 1.0), 8)

func test_fit_font_size_keeps_the_preferred_size_when_it_already_fits() -> void:
	assert_eq(UiDraw.fit_font_size(FONT, "OK", 12, 8, 1000.0), 12)

func test_with_alpha_scales_the_alpha_channel_only() -> void:
	var result: Color = UiDraw.with_alpha(Color(0.2, 0.4, 0.6, 0.8), 0.5)

	assert_almost_eq(result.r, 0.2, 0.001)
	assert_almost_eq(result.g, 0.4, 0.001)
	assert_almost_eq(result.b, 0.6, 0.001)
	assert_almost_eq(result.a, 0.4, 0.001)

func test_angular_points_cut_the_four_corners() -> void:
	var rect := Rect2(0.0, 0.0, 100.0, 60.0)
	var points: PackedVector2Array = UiDraw.angular_points(rect, 10.0)

	assert_eq(points.size(), 8)
	assert_eq(points[0], Vector2(10.0, 0.0))
	assert_eq(points[2], Vector2(100.0, 10.0))
	assert_eq(points[4], Vector2(90.0, 60.0))
	assert_eq(points[6], Vector2(0.0, 50.0))

func test_diamond_points_are_centered_on_the_radius() -> void:
	var points: PackedVector2Array = UiDraw.diamond_points(Vector2(50.0, 50.0), 10.0)

	assert_eq(points.size(), 4)
	assert_eq(points[0], Vector2(50.0, 40.0))
	assert_eq(points[1], Vector2(60.0, 50.0))
	assert_eq(points[2], Vector2(50.0, 60.0))
	assert_eq(points[3], Vector2(40.0, 50.0))

func test_circle_points_have_the_requested_number_of_vertices() -> void:
	var points: PackedVector2Array = UiDraw.circle_points(Vector2.ZERO, 20.0, 8)

	assert_eq(points.size(), 8)
	for point in points:
		assert_almost_eq(point.length(), 20.0, 0.001)
