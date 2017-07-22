register_command('build', array(
	'description': 'Toggles region member build permissions.',
	'usage': '/build [on|off]',
	'tabcompleter': closure(@alias, @sender, @args, @info) {
		return(array());
	},
	'executor': closure(@alias, @sender, @args, @info) {;
		@region = '';
		@state = 'toggle';
		if(array_size(@args) == 2) {
			if(sk_region_exists(pworld(), @args[0])) {
				@region = @args[0];
				@state = @args[1];
			} else if(sk_region_exists(pworld(), @args[1])) {
				@region = @args[1];
				@state = @args[0];
			} else {
				die(color('gold').'Unknown region.');
			}
		} else if(array_size(@args) == 1) {
			if(sk_region_exists(pworld(), @args[0])) {
				@region = @args[0];
			} else {
				@region = array_get(sk_current_regions(), -1, '');
				@state = @args[0];
			}
		} else {
			@region = array_get(sk_current_regions(), -1, '');
		}
		
		if(!@region) {
			die(color('gold').'Unknown region.');
		} else if((!array_contains(sk_region_owners(@region, pworld())['players'], puuid())
		&& !has_permission('group.moderator'))) {
			die(color('gold').'You do not own this region.');
		}
		
		if(@state === 'toggle') {
			foreach(@flag in sk_region_info(@region, pworld(), 3)) {
				if(@flag[0] === 'block-break') {
					@state = if(@flag[1] === 'DENY', 'allow', 'deny');
					break();
				}
			}
			if(@state === 'toggle') {
				@state = 'deny';
			}
		}
		
		switch(@state) {
			case 'on':
			case 'allow':
			case 'true':
				sk_region_flag(pworld(), @region, 'block-break', 'ALLOW', 'members');
				sk_region_flag(pworld(), @region, 'block-place', 'ALLOW', 'members');
				msg('Members are now allowed to build in '.@region);
		
			case 'off':
			case 'deny':
			case 'false':
				sk_region_flag(pworld(), @region, 'block-break', 'DENY', 'nonowners');
				sk_region_flag(pworld(), @region, 'block-place', 'DENY', 'nonowners');
				msg('Members are now prohibited from building in '.@region);
		
			default:
				die(color('gold').'Unknown state.');
		}
	}
));
