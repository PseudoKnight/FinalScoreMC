array_push(@pvp['binds'], @id.'railgun')
bind(player_interact, array('id': @id.'railgun'), array('item': 175, 'button': 'right'), @e, assign(@id, @id)) {
	#@start = nano_time()

	@pvp = import('pvp'.@id)
	if(!array_index_exists(@pvp['players'], player()), die())
	@origin = _relative(ploc(), 'up', 2.3)
	@facing = pfacing(player())
	@facing[0] = @facing[0] + 90
	@facing[1] = 0 - @facing[1]
	@x = cos(to_radians(@facing[0])) * cos(to_radians(@facing[1]))
	@y = sin(to_radians(@facing[1]))
	@z = sin(to_radians(@facing[0])) * cos(to_radians(@facing[1]))
	@n = 0
	@loc = @origin[]

	#msg(((nano_time() - @start) / 1000000).'ms'.' - START GET BLOCKS')
	
	@entities = array()
	@previouschunkx = 0
	@previouschunkz = 0
	
	# SOMETHING LIKE THIS WOULD GET CORNER BLOCKS
	# @newblocklocx = floor(@newloc[x])
	# @newblocklocz = floor(@newloc[z])

	# if(@newblocklocx != @oldblocklocx
	# && @newblocklocz != @oldblocklocz) {
	  # @distx = @newblocklocx - @oldloc[x]
	  # @distz = @newblocklocz - @oldloc[z]
	  # if(@distx < @distz) {
		# if( _is_solid(@newloc[x], @oldloc[z])){
		  # break()
		# } 
	  # } else {
		# if(_is_solid(@oldloc[x], @newloc[z])) {
		  # break()
		# }
	  # }
	# }
	
	while(@n < 80) {
		@loc['x'] += @x
		@loc['y'] += @y
		@loc['z'] += @z
		if(get_block_info(@loc, 'solid')) {
			play_effect(@loc, 'lava_pop', array('particleCount': 8))
			break()
		} else {
			@currentchunkx = floor(@loc['x'] / 16)
			@currentchunkz = floor(@loc['z'] / 16)
			if(@currentchunkx != @previouschunkx
			|| @currentchunkz != @previouschunkz) {
				foreach(@e in all_entities('custom', @currentchunkx, @currentchunkz)) {
					if(is_entity_living(@e)
					&& (entity_type(@e) != 'PLAYER'
					|| get_player_from_entity_id(@e) != player())) {
						@entities[] = @e
					}
				}
				@previouschunkx = @currentchunkx
				@previouschunkz = @currentchunkz
			}
			play_effect(@loc, array('flame', 'crit', 'cloud')[rand(3)], array('speed': 0, 'radius': 64))
			@n++
		}
	}
	
	#msg(((nano_time() - @start) / 1000000).'ms'.' - CALCULATE HITS')
	
	foreach(@e in @entities) {
		@eloc = entity_loc(@e)
		@eloc['y'] += 1.5
		@dist = _squared_distance_to_segment(@eloc, @origin, @loc)
		@hit = false
		if(@dist < 0.5625) { # 0.75 ^ 2
			@hit = true
		} else if(@dist < 2.25) { # (0.75 * 2) ^ 2
			@eloc['y'] -= 1
			@dist = _squared_distance_to_segment(@eloc, @origin, @loc)
			if(@dist < 0.5625) { # 0.75 ^ 2
				@hit = true
			}
		}
		if(@hit) {
			damage_entity(@e, 20, pinfo(player(), 13))
			play_effect(@eloc, 'lava_pop', array('particleCount': 4))
			play_sound(@origin, array('sound': 'SUCCESSFUL_HIT'), player())
		}
	}
	
	#msg(((nano_time() - @start) / 1000000).'ms'.' - END RAILGUN')
	
	play_sound(ploc(), array('sound': 'ZOMBIE_REMEDY', 'pitch': 1.8, 'volume': 3))
	@item = pinv(player(), null)
	@item['qty'] -= 1
	queue_clear(player().'railgun')
	if(@item['qty'] == 0) {
		set_pinv(array('null': null))
	} else { 
		@item['type'] = 402
		@item['name'] = 'FIREWORK_CHARGE'
		set_pinv(array('null': @item))
		@slot = pinfo(player(), 15)
		queue_delay(8000, player().'railgun')
		queue_push(closure(){
			if(ponline(player())) {
				@item = pinv(player(), @slot)
				if(!is_null(@item) && @item['type'] == 402) {
					play_sound(ploc(), array('sound': 'FIZZ', 'pitch': 0))
					@inv = array()
					@item['type'] = 175
					@item['name'] = 'DOUBLE_PLANT'
					@inv[@slot] = @item
					set_pinv(@inv)
				}
			}
		}, player().'railgun')
	}
}