proc('_check_radius', @radii,
	if(!has_permission('worldedit.radiuslimitbypass')) {
		@radii = split(',', @radii)
		foreach(@radii, @radius,
			if(@radius > 32, die('Radius limit exceeded. (32)'))
		)
	}
	run(get_cmd())
)