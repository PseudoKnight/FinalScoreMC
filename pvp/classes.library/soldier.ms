switch(@action) {
case 'load':
	bind(player_interact, array('id': @player.'grenade'), array('player': @player, 'item': 273), @e) {
		if(!ptake_item(player(), array('name': 'STONE_SPADE'))) {
			die();
		}
		@loc = _relative(ploc(), 'up', 2);
		@armorStand = spawn_entity('ARMOR_STAND', 1, @loc)[0];
		set_entity_spec(@armorStand, array('visible': false, 'small': true, 'arms': true));
		set_mob_equipment(@armorStand, array('WEAPON': array('name': 'STONE_SPADE')));
		@loc['yaw'] = @loc['yaw'] + 90;
		@loc['pitch'] = 0 - @loc['pitch'];
		@x = 1.40 * cos(to_radians(@loc['yaw'])) * cos(to_radians(@loc['pitch']));
		@y = max((1.40 * sin(to_radians(@loc['pitch']))) + 0.2, 0.2);
		@z = 1.40 * sin(to_radians(@loc['yaw'])) * cos(to_radians(@loc['pitch']));
		set_entity_velocity(@armorStand, array(@x, @y, @z));
		play_sound(@loc, array('sound': 'IRONGOLEM_THROW'));
		set_timeout(4000, closure(){
			try {
				explosion(entity_loc(@armorStand), 3, true);
				entity_remove(@armorStand);
			} catch(BadEntityException @ex) {
				// grenade no longer exists
			}
		});
	}

case 'unload':
	unbind(@player.'grenade');
}
