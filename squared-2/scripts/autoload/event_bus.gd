extends Node

signal squares_changed(value: float)
signal vertices_changed(value: int)
signal prestige_changed(value: int)
signal grid_changed()
signal square_selected(square_id: String)
signal story_message(message: String)
signal vertex_upgrade_purchased(upgrade_id: String)
signal passive_generator_unlocked(generator_id: String)
signal passive_generator_upgraded(generator_id: String)
signal grid_upgraded(new_grid_size: int)
signal prestige_trait_reveal(target_square_id: String, trait_family_display: String, trait_rarity_display: String, trait_roman_stack: String, square_title: String)
