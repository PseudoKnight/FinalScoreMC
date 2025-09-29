// Bowcaster
bind('player_interact', null, array(hand: 'main_hand', button: 'right', itemname: 'CROSSBOW'), @event) {
	if(pcooldown('CROSSBOW') 
	|| !@event['item']['meta']
	|| @event['item']['meta']['display'] !== 'Bowcaster'
	|| !@event['item']['meta']['projectiles']) {
		die();
	}
	set_pcooldown('CROSSBOW', 5);
	cancel();

	@trace = ray_trace();
	@loc = @trace['origin'];
	@target = @trace['location'];

	@loc['y'] -= 0.24;
	@spawnLoc = @loc[];
	@spawnLoc['pitch'] = 0;
	@yaw = array_remove(@spawnLoc, 'yaw');
	@pitch = get_pitch(@spawnLoc, @target);
	@loc['pitch'] = @pitch;

	// get blast rotation
	@y = -to_radians(@yaw) * 0.5;
	@p = to_radians(@pitch) * 0.5;
	@leftRotation = array(
		w: cos(@p) * cos(@y),
		x: sin(@p) * cos(@y),
		y: cos(@p) * sin(@y),
		z: -sin(@p) * sin(@y),
	);

	play_sound(@loc, array(sound: 'ENTITY_ALLAY_HURT', pitch: 0.5, volume: 3));
	play_sound(@loc, array(sound: 'ENTITY_IRON_GOLEM_REPAIR', pitch: 2, volume: 3));
	@laser = spawn_entity('ITEM_DISPLAY', 1, @spawnLoc, closure(@laser){
		set_entity_saves_on_unload(@laser, false);
		set_display_entity(@laser, array(
			brightness: 15,
			teleportduration: 1,
			transformation: array(
				scale: array(x: 0.03125, y: 0.03125, z: 1.0),
				translation: array(x: 0, y: 0, z: 0),
				leftRotation: @leftRotation)));
		set_entity_spec(@laser, array(item: array(name: 'OCHRE_FROGLIGHT')));
	})[0];

	if(get_block(@loc) === 'AIR') {
		set_blockdata(@loc, array(block: 'light', level: 9));
	}

	@distance = array(0);
	set_interval(50, 0, closure(){
		@distance[0] += 4;
		if(@distance[0] > 96) {
			try(entity_remove(@laser))
			if(get_block(@loc) === 'LIGHT') {
				set_block(@loc, 'AIR');
			}
			clear_task();
			die();
		}
		@trace = ray_trace(player(), @loc, 4, 0.125);
		@hit = @trace['hitblock'];
		foreach(@entity in @trace['entities']) {
			if(has_scoreboard_tag(@entity['uuid'], 'ship')) {
				entity_remove(@entity['uuid']);
			} else {
				@type = entity_type(@entity['uuid']);
				if(@type === 'PLAYER' && pmode(@entity['uuid']) === 'SPECTATOR') {
					continue();
				}
				if(@type !== 'ARMOR_STAND') {
					damage_entity(@entity['uuid'], 12, puuid());
				}
			}
			@hit = true;
			break();
		}
		if(@hit) {
			try(entity_remove(@laser))
			if(get_block(@loc) === 'LIGHT') {
				set_block(@loc, 'AIR');
			}
			@loc['x'] = @trace['location']['x'];
			@loc['y'] = @trace['location']['y'];
			@loc['z'] = @trace['location']['z'];
			play_sound(@loc, array(sound: 'ENTITY_GENERIC_BURN', pitch: 2, volume: 5));
			play_sound(@loc, array(sound: 'ENTITY_IRON_GOLEM_DAMAGE', pitch: 1.5, volume: 5));
			play_sound(@loc, array(sound: 'BLOCK_NOTE_BLOCK_BASEDRUM', pitch: 2, volume: 5));
			spawn_particle(@loc, array(particle: 'LAVA', count: 25, force: true, xoffset: 0.25, yoffset: 0.25, zoffset: 0.25));
			if(get_block(@loc) === 'AIR') {
				set_blockdata(@loc, array(block: 'light', level: 15));
			}
			set_interval(150, closure(){
				@blockdata = get_blockdata(@loc);
				if(@blockdata['block'] === 'light') {
					if(@blockdata['level'] < 2) {
						set_block(@loc, 'AIR');
						clear_task();
					} else {
						set_blockdata(@loc, array(block: 'light', level: @blockdata['level'] - 1));
					}
				} else {
					clear_task();
				}
			});
			clear_task();
		} else {
			if(get_block(@loc) === 'LIGHT') {
				set_block(@loc, 'AIR');
			}
			@loc['x'] = @trace['location']['x'];
			@loc['y'] = @trace['location']['y'];
			@loc['z'] = @trace['location']['z'];
			set_entity_loc(@laser, array(@loc['x'], @loc['y'], @loc['z'], @loc['world']));
			if(get_block(@loc) === 'AIR') {
				set_blockdata(@loc, array(block: 'light', level: 9));
			}
		}
	});
}