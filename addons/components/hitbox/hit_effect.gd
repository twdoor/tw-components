@icon("uid://js7d1lylt15w")
class_name HitEffect extends Resource

## Base hit payload used by HitboxComponent2D.
## Extend this resource in a project to add game-specific hit data.
@export var damage: float = 0.0


## Returns a copy that can be safely passed to receivers for this hit.
## Override this in subclasses if your effect needs custom copy behavior.
func duplicate_for_hit(deep: bool = true) -> HitEffect:
	var copied := duplicate(deep)
	if copied is HitEffect:
		return copied

	var fallback := HitEffect.new()
	fallback.damage = damage
	return fallback
