class_name ProgressionDiscoveryPolicy
extends RefCounted


static func should_reveal(current_currency: float, next_cost: float, visibility_ratio: float) -> bool:
	if next_cost <= 0.0:
		return true

	return current_currency >= next_cost * clampf(visibility_ratio, 0.0, 1.0)
