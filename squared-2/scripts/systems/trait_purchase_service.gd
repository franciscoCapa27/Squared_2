class_name TraitPurchaseService
extends RefCounted

const COST_BASE := 15.0
const COST_MULTIPLIER := 1.5
const VERTEX_GAIN_DIVISOR := 25.0


static func calculate_cost(trait_purchase_count: int, run_cost_multiplier: float) -> float:
	var base_cost: float = COST_BASE * pow(
		COST_MULTIPLIER,
		float(maxi(0, trait_purchase_count))
	)
	return ceil(base_cost * maxf(0.0, run_cost_multiplier))


static func calculate_vertices_gain(cost: float) -> int:
	return max(1, int(floor(sqrt(maxf(0.0, cost) / VERTEX_GAIN_DIVISOR))))
