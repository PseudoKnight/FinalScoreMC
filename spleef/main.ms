bind(player_interact, null, array('block': 68), @e) {
	@sign = get_sign_text(@e['location'])
	
	if(@sign[0] == '[Spleef]'
	&& @sign[2] == 'Join') {
	
		@id = to_lower(@sign[1])
		if(!has_value('spleef', @id)) {
			die()
		}
	
		@spl = import('spleef.'.@id)
		if(!@spl) {
			@spl = array(
				'state': 0,
				'nextplayers': array(),
				'players': array(),
			)
		}
		
		if(array_contains(@spl['nextplayers'], player())) {
			die('You\'ve already joined.')
		}
		
		array_push(@spl['nextplayers'], player())

		foreach(@i: @player in @spl['nextplayers']) {
			if(!ponline(@player) || !array_contains(sk_current_regions(@player), 'spl_'.@id)) {
				array_remove(@spl['nextplayers'], @i)
			}
		}
		
		set_sign_text(@e['location'], array(@sign[0], @sign[1], @sign[2], array_size(@spl['nextplayers'])))
		
		export('spleef.'.@id, @spl)	
	
		if(@spl['state'] == 0 && array_size(@spl['nextplayers']) >= 2) {
			include('includes.library/core.ms')
			_spl_queue_start(@id)
		}
	}
}