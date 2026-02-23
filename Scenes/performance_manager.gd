## performance_manager.gd
## Add this as an Autoload singleton: Project > Project Settings > Autoload
## Name it: PerformanceManager

extends Node

# ─── Quality Presets ───────────────────────────────────────────────
enum Preset { ULTRA_LOW, LOW, MEDIUM, HIGH }

var current_preset: int = Preset.LOW

# ─── Called once at game start ─────────────────────────────────────
func _ready() -> void:
	# Detect low-end hardware automatically
	var vram_mb = Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1_000_000
	var cpu_count = OS.get_processor_count()

	if vram_mb < 256 or cpu_count <= 2:
		apply_preset(Preset.ULTRA_LOW)
	else:
		apply_preset(Preset.LOW)   # Safe default; user can raise it in menu

# ─── Apply a full quality preset ──────────────────────────────────
func apply_preset(preset: int) -> void:
	current_preset = preset
	match preset:
		Preset.ULTRA_LOW:
			_apply_ultra_low()
		Preset.LOW:
			_apply_low()
		Preset.MEDIUM:
			_apply_medium()
		Preset.HIGH:
			_apply_high()

# ─── ULTRA LOW  (integrated graphics / very old PCs) ──────────────
func _apply_ultra_low() -> void:
	# Resolution scale (render at 50%, display at 100%)
	get_viewport().scaling_3d_scale = 0.5
	get_viewport().msaa_3d = Viewport.MSAA_DISABLED
	get_viewport().screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED
	get_viewport().use_debanding = false

	# Shadow quality
	RenderingServer.directional_shadow_atlas_set_size(512, true)
	ProjectSettings.set_setting("rendering/lights_and_shadows/directional_shadow/size", 512)

	# Disable expensive effects
	RenderingServer.environment_set_ssao(
		get_viewport().get_viewport_rid(), false, 0,0,0,0,0,0,0,0)
	RenderingServer.environment_set_glow(
		get_viewport().get_viewport_rid(), false, [0.0,0.0,0.0,0.0,0.0,0.0,0.0],
		0,0,0,0,0,RenderingServer.ENV_GLOW_BLEND_MODE_ADDITIVE,0,false)
	RenderingServer.environment_set_ssr(
		get_viewport().get_viewport_rid(), false, 0, 0, 0, 0)
	RenderingServer.environment_set_sdfgi(
		get_viewport().get_viewport_rid(), false, false, false,
		RenderingServer.ENV_SDFGI_Y_SCALE_75_PERCENT, 0, 0, 0, false, 0, 0)

	# Limit FPS to reduce heat & stuttering on weak CPUs
	Engine.max_fps = 30
	# Physics ticks (lower = less CPU load, but less precise)
	Engine.physics_ticks_per_second = 30

	print("[PerformanceManager] Preset: ULTRA LOW")

# ─── LOW  (no dedicated GPU, older integrated) ───────────────────
func _apply_low() -> void:
	get_viewport().scaling_3d_scale = 0.65
	get_viewport().msaa_3d = Viewport.MSAA_DISABLED
	get_viewport().screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED
	get_viewport().use_debanding = false

	RenderingServer.directional_shadow_atlas_set_size(1024, true)

	Engine.max_fps = 60
	Engine.physics_ticks_per_second = 60

	print("[PerformanceManager] Preset: LOW")

# ─── MEDIUM ───────────────────────────────────────────────────────
func _apply_medium() -> void:
	get_viewport().scaling_3d_scale = 0.85
	get_viewport().msaa_3d = Viewport.MSAA_2X
	get_viewport().screen_space_aa = Viewport.SCREEN_SPACE_AA_FXAA

	RenderingServer.directional_shadow_atlas_set_size(2048, true)

	Engine.max_fps = 60
	Engine.physics_ticks_per_second = 60

	print("[PerformanceManager] Preset: MEDIUM")

# ─── HIGH ─────────────────────────────────────────────────────────
func _apply_high() -> void:
	get_viewport().scaling_3d_scale = 1.0
	get_viewport().msaa_3d = Viewport.MSAA_4X
	get_viewport().screen_space_aa = Viewport.SCREEN_SPACE_AA_FXAA
	get_viewport().use_debanding = true

	RenderingServer.directional_shadow_atlas_set_size(4096, true)

	Engine.max_fps = 0  # Uncapped
	Engine.physics_ticks_per_second = 60

	print("[PerformanceManager] Preset: HIGH")
