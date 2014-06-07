proc('_spawn_mob', @mob, @qty, @loc, @owner = 'Notch') {
	@mob = _get_mob(@mob)
	if(!@mob, return(array()))
	@mobs = spawn_mob(@mob['type'], @qty, @loc)
	foreach(@mobs, @m,
		if(array_index_exists(@mob, 'name'), set_mob_name(@m, @mob['name']))
		if(array_index_exists(@mob, 'gear'), set_mob_equipment(@m, @mob['gear']))
		if(array_index_exists(@mob, 'droprate'), set_equipment_droprates(@m, @mob['droprate']))
		if(array_index_exists(@mob, 'tags'), set_entity_spec(@m, @mob['tags']))
		if(array_index_exists(@mob, 'tame'), tame_mob(@owner, @m))
		if(array_index_exists(@mob, 'health')) {
			set_max_health(@m, @mob['health'])
			set_entity_health(@m, 100)
		}
		set_entity_persistence(@m, true)
	)
	if(array_index_exists(@mob, 'effects')) {
		set_timeout(50, closure(
			foreach(@mobs, @m,
				foreach(@mob['effects'], @e,
					try(set_mob_effect(@m, @e['id'], @e['strength'], @e['seconds'], true))
				)
			)
		))
	}
	return(@mobs)
}

proc('_get_mob', @mob = null,
	@mobtypes = reflect_pull('enum', 'Mobs')
	if(!@mob) {
		@mob = @mobtypes[rand(array_size(@mobtypes))]
	} else {
		@mobtype = split(':', @mob)
		if(array_contains_ic(@mobtypes, @mobtype[0])) {
			@mob = array('type': @mob)
		} else {
			@mob = get_value('mob.'.@mob)
		}
	}
	return(@mob)
)