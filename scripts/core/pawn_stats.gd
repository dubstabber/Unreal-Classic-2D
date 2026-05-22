class_name PawnStats
extends Resource
## Tunable movement parameters for a Pawn. All values in pixels / pixels-per-second at
## the project's base resolution (480x270). One unit = one pixel.

# Ground movement
@export var run_speed: float = 180.0
@export var run_accel: float = 1800.0
@export var run_friction: float = 1600.0
@export var crouch_speed: float = 90.0
@export var crouch_accel: float = 1200.0

# Air movement
@export var air_speed: float = 180.0
@export var air_accel: float = 700.0
@export var air_friction: float = 200.0

# Gravity / jump
@export var gravity: float = 900.0
@export var max_fall_speed: float = 700.0
@export var jump_impulse: float = 280.0
@export var jump_hold_gravity_scale: float = 0.45  # while jump held, gravity is scaled by this until apex
@export var coyote_seconds: float = 0.10
@export var jump_buffer_seconds: float = 0.12

# Dodge (double-tap)
@export var dodge_tap_window_msec: int = 300
@export var dodge_horizontal_impulse: float = 280.0
@export var dodge_vertical_impulse: float = 150.0
@export var dodge_cooldown_msec: int = 700

# Dodge-jump (press jump shortly after dodge for extra height)
@export var dodge_jump_window_msec: int = 350
@export var dodge_jump_impulse: float = 200.0

# Wall-dodge (dodge while airborne + touching wall)
@export var wall_dodge_horizontal_impulse: float = 300.0
@export var wall_dodge_vertical_impulse: float = 240.0

# Collision sizing
@export var standing_height: float = 20.0
@export var crouch_height: float = 12.0
@export var hitbox_width: float = 10.0
