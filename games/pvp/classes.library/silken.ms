switch(@action) {
case 'load':
	set_peffect(@player, 'MINING_FATIGUE', 1, 9999, true, false);
	bind('entity_damage', array(id: @player.'damage'), array(type: 'PLAYER', cause: 'ENTITY_ATTACK'), @event, @p = @player) {
		if(@event['damager'] == @p) {
			@weapon = pinv(@p, null);
			if(@weapon && @weapon['name'] == 'STONE_HOE') {
				modify_event('amount', pattack_cooldown(@p) * 2);
				set_mob_effect(@event['id'], 'wither', 1, pattack_cooldown(@p) * 7);
			}
		}
	}

	bind('player_interact', array(id: @player.'web'), array(player: @player, button: 'right', itemname: 'COBWEB'), @event, @pvp) {
		@item = pinv(player(), null);
		if(@item && pcooldown(@item['name']) == 0) {
			@item['qty'] = 1;
			ptake_item(@item);
			set_pcooldown(@item['name'], 10000 / 50);
			@loc = location_shift(ploc(), 'up', 2.5);
			@v = get_vector(@loc);
			@loc['x'] += @v['x'];
			@loc['y'] += @v['y'];
			@loc['z'] += @v['z'];
			for(@i = 0, @i < 90, @i++) {
				queue_push(closure(){
					@loc['x'] += @v['x'];
					@loc['y'] += @v['y'];
					@loc['z'] += @v['z'];
					@block = get_block(@loc);
					if(@block == 'AIR') {
						@blockLoc = array(
							floor(@loc['x']),
							floor(@loc['y']),
							floor(@loc['z']),
							@loc['world']
						);
						set_block(@blockLoc, 'COBWEB');
						@pvp['players'][player()]['blocks'][] = @blockLoc;
						play_sound(@loc, array(sound: 'ENTITY_SPIDER_AMBIENT', pitch: 2));
					} else if(@block != 'COBWEB') {
						queue_clear(player().'web');
					}
				}, player().'web');
			}
		}
	}

	bind('player_interact', array(id: @player.'webbreak'), array(button: 'right', block: 'COBWEB'), @event, @pvp, @player) {
		if(!array_index_exists(@pvp['players'], player())) {
			die();
		}
		@blocks = @pvp['players'][@player]['blocks'];
		if(@blocks) {
			foreach(@i: @block in @blocks) {
				if(@block[0] == @event['location'][0] && @block[1] == @event['location'][1] && @block[2] == @event['location'][2]) {
					set_block(@block, 'AIR');
					array_remove(@blocks, @i);
					play_sound(@block, array(sound: 'BLOCK_WOOL_BREAK', volume: 0.7));
					play_sound(ploc(@player), array(sound: 'BLOCK_NOTE_BLOCK_BASS', pitch: 1.5 + rand() * 0.5, volume: 0.3), @player);
					@event['location']['x'] += 0.5;
					@event['location']['y'] += 0.5;
					@event['location']['z'] += 0.5;
					spawn_particle(@event['location'], array(particle: 'BLOCK_CRACK', block: 'COBWEB', count: 10, xoffset: 0.5, yoffset: 0.5, zoffset: 0.5));
					break();
				}
			}
		}
	}

	set_interval(50, closure(){
		try {
			if(pmode(@player) == 'SPECTATOR'
			|| !array_index_exists(@pvp['players'], @player)
			|| @pvp['players'][@player]['class'] != 'silken') {
				clear_task();
				die();
			}
			@blocks = @pvp['players'][@player]['blocks'];
			if(@blocks) {
				@loc = ploc(@player);
				@minX = floor(@loc['x'] - 1);
				@minY = floor(@loc['y']);
				@minZ = floor(@loc['z'] - 1);
				@world = @loc['world'];
				for(@x = @minX, @x <= @minX + 2, @x++) {
					for(@y = @minY, @y <= @minY + 3, @y++) {
						for(@z = @minZ, @z <= @minZ + 2, @z++) {
							if(get_block(array(@x, @y, @z, @world)) == 'COBWEB') {
								foreach(@i: @block in @blocks) {
									if(@block[0] == @x && @block[1] == @y && @block[2] == @z) {
										set_block(@block, 'AIR');
										array_remove(@blocks, @i);
										break();
									}
								}
							}
						}
					}
				}
			}
		} catch(Exception @ex) {
			clear_task();
		}
	})

case 'unload':
	unbind(@player.'damage');
	unbind(@player.'web');
	unbind(@player.'webbreak');
	foreach(@block in @pvp['players'][@player]['blocks']) {
		set_block(@block, 'AIR');
	}
	@pvp['players'][@player]['blocks'] = array();

}
