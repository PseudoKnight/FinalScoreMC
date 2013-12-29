proc('_spawn_mob', @mob, @qty, @loc,
	@mob = _get_mob(@mob)
	if(!@mob, return(array()))
	@mobs = spawn_mob(@mob['type'], @qty, @loc)
	foreach(@mobs, @m,
		if(array_index_exists(@mob, 'name'), set_mob_name(@m, @mob['name']))
		if(array_index_exists(@mob, 'gear'), set_mob_equipment(@m, @mob['gear']))
		if(array_index_exists(@mob, 'droprate'), set_equipment_droprates(@m, @mob['droprate']))
	)
	if(array_index_exists(@mob, 'effects')) {
		set_timeout(50, closure(
			foreach(@mobs, @m,
				foreach(@mob['effects'], @e,
					try(set_mob_effect(@m, @e['id'], @e['strength'], @e['seconds']))
				)
			)
		))
	}
	return(@mobs)
)

proc('_get_mob', @mob = null,
	@mobs = array(
		'chicken', 'cow', 'creeper', 'ghast', 'pig', 'pigzombie', 'sheep', 'skeleton', 'slime', 'spider', 'squid', 'wolf', 'zombie', 'cavespider', 'enderman', 'silverfish', 'villager', 'blaze', 'enderdragon', 'magmacube', 'mooshroom', 'spiderjockey', 'giant', 'snowgolem', 'ocelot', 'cat', 'irongolem', 'wither', 'bat', 'witch', 'horse'
	)
	if(!@mob) {
		@mob = @mobs[rand(array_size(@mobs))]
	} else {
		@mobtype = split(':', @mob)
		if(array_contains(@mobs, @mobtype[0])) {
			@mob = array('type': @mob)
		} else {
			@mob = get_value('mob.'.@mob)
		}
	}
	return(@mob)
)