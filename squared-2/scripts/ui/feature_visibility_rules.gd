extends RefCounted
class_name FeatureVisibilityRules


static func should_show_passive_panel() -> bool:
	return PassiveSystem.has_any_unlocked_generator()


static func should_show_vertex_shop_access() -> bool:
	return GameState.vertices > 0 or GameState.prestige_count > 0


static func should_show_prestige_panel() -> bool:
	return GameState.can_prestige() or GameState.prestige_count > 0 or GameState.vertices > 0


static func should_show_run_upgrades_panel() -> bool:
	return RunUpgradeSystem.has_any_visible_run_upgrade()


static func should_show_square_details_panel(selected_square_id: String) -> bool:
	return selected_square_id.strip_edges() != ""


static func should_show_achievement_summary_panel() -> bool:
	return AchievementSystem.get_unlocked_count() > 0


static func should_show_grid_upgrade_button() -> bool:
	return GameState.grid_size < GameState.MAX_GRID_SIZE and (
		GameState.squares >= GameState.get_grid_upgrade_cost()
		or GameState.grid_size > GameState.INITIAL_GRID_SIZE
	)
