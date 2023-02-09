/*
	Core arena preparation (can be overriden by arena code)
*/
proc _arena_prepare(@pvp) {}

proc _arena_load(@pvp) {
	@id = @pvp['id'];
	@pvp['arena'] = get_value('arena', @id);
	if(is_null(@pvp['arena'])) {
		die(color('gold').'Can\'t find that arena.');
	}

	if(array_index_exists(@pvp['arena'], 'options')) {
		delete_virtual_inventory(@id.'options');
		unbind(@id.'options');
	}

	// Select Arena by Votes
	@childid = '';
	if(array_index_exists(@pvp['arena'], 'arenaselect') && @pvp['arena']['arenaselect']['type'] == 'vote') {
		@voted = array_filter(@pvp['players'], closure(@key, @value){
			return(array_index_exists(@value, 'arena'));
		});
		@picked = array_get(array_rand(@voted), 0, '');
		if(@picked) {
			@childid = @pvp['players'][@picked]['arena'];
			@pvp['arenapicked'] = @picked;

			// Store total votes
			if(array_size(@pvp['players']) > 1) { // don not store if testing with one player
				if(!array_index_exists(@pvp['arena'], 'arenavotes')) {
					@pvp['arena']['arenavotes'] = associative_array();
				}
				foreach(@vote in @voted) {
					@arenaID = @vote['arena'];
					if(!array_index_exists(@pvp['arena']['arenavotes'], @arenaID)) {
						@pvp['arena']['arenavotes'][@arenaID] = 1;
					} else {
						@pvp['arena']['arenavotes'][@arenaID]++;
					}
				}
				store_value('arena', @id, @pvp['arena']);
			}
		}
	}

	# Set defaults
	@defaults = array(
		mode: 'dm',
		ff: 'true',
		flags: array(),
		respawnmode: 'normal',
		delay: 10,
	);
	@pvp['arena'] = array_merge(@defaults, @pvp['arena']);

	# Get child or parent arena settings
	@primaryName = _to_upper_camel_case(@id);
	@secondaryName = null;
	if(array_index_exists(@pvp['arena'], 'parent')) {
		@parent = get_value('arena.'.@pvp['arena']['parent']);
		if(!@parent) {
			die('Can\'t find parent arena.');
		}
		@primaryName = _to_upper_camel_case(@pvp['arena']['parent']);
		@secondaryName = _to_upper_camel_case(@id);
		@pvp['arena'] = array_merge(@parent, @pvp['arena']);
		if(array_contains(@pvp['arena']['flags'], 'script')){
			@pvp['arenascripts'][] = @pvp['arena']['parent'];
			@pvp['arenascripts'][] = @id;
		}
	} else if(array_index_exists(@pvp['arena'], 'arenaselect')) {
		if(!@childid) {
			@childid = array_get_rand(@pvp['arena']['arenaselect']['arenas']);
		}
		@child = get_value('arena', @childid);
		if(!@child) {
			die('Can\'t find child arena.');
		}
		@secondaryName = _to_upper_camel_case(@childid);
		@pvp['arena'] = array_merge(@pvp['arena'], @child);
		if(array_contains(@pvp['arena']['flags'], 'script')){
			@pvp['arenascripts'][] = @id;
			@pvp['arenascripts'][] = @childid;
		}
	} else if(array_contains(@pvp['arena']['flags'], 'script')){
		@pvp['arenascripts'][] = @id;
	}
	@pvp['title'] = @primaryName.if(@secondaryName, ': '.@secondaryName);
	@arena = @pvp['arena'];

		// Check shared regions
	if(array_index_exists(@arena, 'sharedarenas')) {
		foreach(@arenaid in @arena['sharedarenas']) {
			@otherpvp = import('pvp'.@arenaid);
			if(@otherpvp && @otherpvp['running']) {
				die('Another PVP match is running in that region.');
			}
		}
	}

	# Check if arena is in testing
	if(array_contains(@arena['flags'], 'debug') && !has_permission('group.builder')) {
		die('This arena is still in testing and can only be started by Builders.');
	}

	# Check if enough players
	if(!has_permission('group.engineer') && array_size(@pvp['players']) < if(array_index_exists(@arena, 'min'), @arena['min'], 2)) {
		die('There aren\'t enough players. ('.array_size(@pvp['players']).')');
	}

	# Check arena settings
	if(!array_index_exists(@arena, 'lobby'), die('No lobby defined for arena.'));
	if(!array_index_exists(@arena, 'region'), die('No region defined for arena.'));

		# Configure remaining arena settings
	if(array_contains(@arena['flags'], 'keepinventory'), @arena['denydrop'] = 'all');
	if(array_index_exists(@arena, 'classes')) {
		if(array_size(@arena['classes']) > 1){
			@arena['delay'] = 45;
		}
		if(!array_index_exists(@arena, 'class_picking'), @arena['class_picking'] = 'player');
	}

	# Dynamically determine if it should be a team game
	if(@arena['mode'] === 'ddm' || @arena['mode'] === 'koth') {
		@moderesult = '';
		if(@arena['mode'] == 'ddm') {
			@arena['mode'] = 'dm';
			@voted = array_filter(@pvp['players'], closure(@key, @value){
				return(array_index_exists(@value, 'mode'));
			});
			@modepicked = array_get(array_rand(@voted), 0, '');
			if(@modepicked) {
				@moderesult = @pvp['players'][@modepicked]['mode'];
				@pvp['modepicked'] = @modepicked;
				@pvp['moderesult'] = @moderesult;
			}
		}
		@size = array_size(@pvp['players']);
		if(@moderesult == 'teams' || @moderesult != 'solo' && @size > 3 && @size % 2 == 0) {
			if(!array_index_exists(@arena, 'team')) {
				@arena['team'] = array(
					array(name: 'Red', color: 'RED'),
					array(name: 'Blue', color: 'BLUE')
				);
			}

			if(array_index_exists(@arena, 'kit')) {
				@arena['kit'][1] = @arena['kit'][0];
			}

		} else if(array_index_exists(@arena, 'team')) {
			array_remove(@arena, 'team');
		}
	}

	if(array_index_exists(@arena, 'team')) {
		// Alternate spawns
		if(array_size(@arena['spawn']) == 1 || !@arena['spawn'][1]) {
			@oldspawns = @arena['spawn'][0][];
			@arena['spawn'] = array(array(), array());
			@team = 0;
			foreach(@spawn in @oldspawns) {
				@arena['spawn'][@team][] = @spawn;
				@team = if(@team == 0, 1, 0);
			}
		// or remove excess spawn groups
		} else {
			while(array_size(@arena['spawn']) > 2) {
				array_remove(@arena['spawn'], rand(array_size(@arena['spawn'])));
			}
			@arena['spawn'] = array_normalize(@arena['spawn']);
		}
	} else {
		// Merge spawns, if needed
		if(array_size(@arena['spawn']) > 1 && @arena['spawn'][1]) {
			@size = array_size(@arena['spawn'][0]);
			@newSpawns = array();
			for(@i = 0, @i < @size, @i++) {
				foreach(@spawns in @arena['spawn']) {
					@newSpawns[] = @spawns[@i];
				}
			}
			@arena['spawn'][0] = @newSpawns;
		}
	}

	// Default scores
	if(!array_index_exists(@arena, 'score')) {
		switch(@arena['mode']) {
			case 'ctf':
				@arena['score'] = 5;
			case 'koth':
				@arena['score'] = 60;
		}
	}

	// Adjust target scores for player counts
	if(@arena['mode'] == 'koth' && !array_index_exists(@pvp, 'team') && array_size(@pvp['players']) > 4) {
		@arena['score'] = integer(@arena['score'] / (array_size(@pvp['players']) - 3));
	}

	return(@arena);
}