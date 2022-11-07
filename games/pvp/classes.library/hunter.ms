proc _class_load(@player, @pvp) {
	bind('projectile_launch', array(id: @player.'huntershoot'), array(type: 'ARROW', shootertype: 'PLAYER'), @event, @player) {
		if(@event['player'] == @player) {
			set_entity_spec(@event['id'], array(damage: 1.0, critical: false));
		}
	}

	bind('item_swap', array(id: @player.'hunterswap', priority: 'HIGHEST'), array(off_hand: 'FIREWORK_ROCKET', player: @player), @event) {
		consume();
	}
}

proc _class_powerup(@player, @pvp) {
	@wolves = entities_in_radius(ploc(@player), 24, 'WOLF');
	@existingWolf = null;
	foreach(@wolf in @wolves) {
		if(get_mob_owner(@wolf) == @player) {
			@existingWolf = @wolf;
			break();
		}
	}
	if(@existingWolf) {
		set_entity_health(@existingWolf, 100);
	} else {
		@pvp['players'][@player]['entities']['wolf'] = spawn_entity('WOLF', 1, entity_loc(puuid(@player)), closure(@wolf) {
			set_mob_owner(@wolf, @player);
			set_entity_spec(@wolf, array(color: array_get_rand(reflect_pull('enum', 'DyeColor'))));
			set_mob_effect(@wolf, 'SPEED', 1, 9999, true, false);
		})[0];
	}
}

proc _class_unload(@player, @pvp) {
	unbind(@player.'huntershoot');
	unbind(@player.'hunterswap');
	try {
		entity_remove(@pvp['players'][@player]['entities']['wolf']);
		array_remove(@pvp['players'][@player]['entities'], 'wolf');
	} catch(Exception @ex) {}
}
