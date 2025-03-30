proc _open_vote_menu(@id) {
	@pvp = import('pvp'.@id);
	if(array_index_exists(@pvp, 'voteMenu')) {
		open_book(@pvp['voteMenu']);
		return();
	}
	@arena = get_value('arena.'.@id);
	@optionCount = array_size(@arena['vote']);
	@pages = array();
	@root = array('');
	@root[] = array(text: '\n----- MENU -----', bold: true, color: 'red');

	if(array_index_exists(@arena['vote'], 'teams')) {
		@root[] = array(
			bold: true,
			text: if(@optionCount < 5, '\n\n', '\n').' ≡ Teams',
			clickEvent: array(action: 'change_page', value: array_size(@pages) + 2));

		@votes = array();
		foreach(@p in @pvp['players']) {
			if(array_index_exists(@p, 'votes', 'teams')) {
				@votes[] = @p['votes']['teams'];
			}
		}
		@page = array('');
		@page[] = array(
			color: 'red',
			bold: true,
			text: ' Teams\n');
		foreach(@value in @arena['vote']['teams']) {
			@page[] = array(
				text: '\n '.if(array_contains(@votes, @value), '☑', '☐').' '.to_upper(@value[0]).@value[1..],
				clickEvent: array(action: 'run_command', value: '/pvp vote '.@id.' teams '.@value));
		}
		@page[] = array(
			bold: true,
			text: '\n\n ≡ MENU',
			clickEvent: array(action: 'change_page', value: 1));
		@pages[] = json_encode(@page);
	}

	if(array_index_exists(@arena['vote'], 'classes')) {
		@root[] = array(
			bold: true,
			text: if(@optionCount < 5, '\n\n', '\n').' ≡ Classes',
			clickEvent: array(action: 'change_page', value: array_size(@pages) + 2));

		@votes = array();
		foreach(@p in @pvp['players']) {
			if(array_index_exists(@p, 'votes', 'classes')) {
				@votes[] = @p['votes']['classes'];
			}
		}
		@page = array('');
		@page[] = array(
			color: 'red',
			bold: true,
			text: ' Classes\n');
		foreach(@value in @arena['vote']['classes']) {
			@page[] = array(
				text: '\n '.if(array_contains(@votes, @value), '☑', '☐').' '.to_upper(@value[0]).@value[1..],
				clickEvent: array(action: 'run_command', value: '/pvp vote '.@id.' classes '.@value));
		}
		@page[] = array(
			bold: true,
			text: '\n\n ≡ MENU',
			clickEvent: array(action: 'change_page', value: 1));
		@pages[] = json_encode(@page);
	}

	if(array_index_exists(@arena['vote'], 'arenas')) {
		@root[] = array(
			bold: true,
			text: if(@optionCount < 5, '\n\n', '\n').' ≡ Arenas',
			clickEvent: array(action: 'change_page', value: array_size(@pages) + 2));

		@page = array('');
		@page[] = array(
			color: 'red',
			bold: true,
			text: ' Arenas');
		@votes = array();
		foreach(@p in @pvp['players']) {
			if(array_index_exists(@p, 'votes', 'arena')) {
				@votes[] = @p['votes']['arena'];
			}
		}
		if(array_contains(@arena['vote']['arenas'], 'random')) {
			@checkBox = '☐';
			if(array_contains(@votes, 'random')) {
				@checkBox = '☑';
			}
			@page[] = array(
				text: '\n '.@checkBox.' Random',
				clickEvent: array(action: 'run_command', value: '/pvp vote '.@id.' arena random'));
		}
		if(array_contains(@arena['vote']['arenas'], 'any')) {
			foreach(@index: @ar in @arena['arenaselect']['arenas']) {
				if(array_size(@page) > 14) {
					@pages[] = json_encode(@page);
					@page = array('');
					@page[] = array(
						color: 'red',
						bold: true,
						text: 'Arena');
				}
				@checkBox = '☐';
				if(array_contains(@votes, @ar)) {
					@checkBox = '☑';
				}
				@page[] = array(
					text: '\n '.@checkBox.' '.to_upper(@ar[0]).substr(@ar, 1),
					clickEvent: array(action: 'run_command', value: '/pvp vote '.@id.' arena '.@ar));
			}
		}
		@pages[] = json_encode(@page);
	}

	if(array_size(@arena['vote']) > 1) {
		@root[] = array(text: '\n\n----------------', bold: true, color: 'red');
		array_insert(@pages, json_encode(@root), 0);
	}
	@pvp['voteMenu'] = @pages;
	open_book(@pages);
}