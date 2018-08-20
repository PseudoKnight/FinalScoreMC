register_command('entitycount', array(
	'description': 'Returns the number of entities of each type in this world.',
	'usage': '/entitycount',
	'permission': 'command.entitycount',
	'tabcompleter': closure(@alias, @sender, @args, @info) {
		return(array());
	},
	'executor': closure(@alias, @sender, @args, @info) {
		@MONSTERS = array('BLAZE', 'CAVE_SPIDER', 'CREEPER', 'DROWNED', 'ELDER_GUARDIAN', 'ENDER_DRAGON', 'ENDERMAN',
				'ENDERMITE', 'EVOKER', 'GHAST', 'GUARDIAN', 'HUSK', 'MAGMA_CUBE', 'PHANTOM', 'PIG_ZOMBIE', 'SHULKER',
				'SILVERFISH', 'SKELETON', 'SPIDER', 'STRAY', 'VEX', 'VINDICATOR', 'WITCH', 'WITHER', 'WITHER_SKELETON',
				'ZOMBIE', 'ZOMBIE_VILLAGER');
		@ANIMALS = array('CHICKEN', 'COW', 'DONKEY', 'HORSE', 'IRON_GOLEM', 'LLAMA', 'MULE',
				'MUSHROOM_COW', 'OCELOT', 'PARROT', 'PIG', 'POLAR_BEAR', 'RABBIT', 'SHEEP',
				'SKELETON_HORSE', 'SNOWMAN', 'TURTLE', 'VILLAGER', 'WOLF', 'ZOMBIE_HORSE');
		@WATERANIMALS = array('COD', 'DOLPHIN', 'SQUID', 'PUFFERFISH', 'SALMON', 'TROPICAL_FISH' );
		@AMBIENT = array('BAT');
		
		@playerCount = array_size(all_players(pworld()));
		@caps = array(
			'MONSTERS': 23 * @playerCount,
			'ANIMALS': 4 * @playerCount,
			'WATERANIMALS': 6 * @playerCount,
			'AMBIENT': 1 * @playerCount,
		);
		
		@entities = all_entities(pworld());
		@specificTypes = associative_array();
		@classTypes = array('MONSTERS': 0, 'ANIMALS': 0, 'WATERANIMALS': 0, 'AMBIENT': 0);
		foreach(@e in @entities) {
			@type = entity_type(@e);
			if(!array_index_exists(@specificTypes, @type)) {
				@specificTypes[@type] = 0;
			}
			@specificTypes[@type]++;
			
			if(array_contains(@MONSTERS, @type)) {
				if(!get_entity_persistence(@e)) {
					@classTypes['MONSTERS']++;
				}
			} else if(array_contains(@ANIMALS, @type)) {
				@classTypes['ANIMALS']++;
			} else if(array_contains(@WATERANIMALS, @type)) {
				if(!get_entity_persistence(@e)) {
					@classTypes['WATERANIMALS']++;
				}
			} else if(array_contains(@AMBIENT, @type)) {
				if(!get_entity_persistence(@e)) {
					@classTypes['AMBIENT']++;
				}
			}
		}
		msg(color('green').'Totals by Entity Type '.color('gray').'(at least 10)');
		@other = 0;
		foreach(@type: @count in @specificTypes) {
			if(@count > 9) {
				msg(@type.': '.@count);
			} else {
				@other += @count;
			}
		}
		msg('OTHER: '.@other);
		msg(color('green').'Type: EntityCount / MaxEstimatedCap '.color('gray').'(discludes persistent)');
		foreach(@classType: @count in @classTypes) {
			msg(@classType.': '.@count.' / '.@caps[@classType]);
		}
	}
));
