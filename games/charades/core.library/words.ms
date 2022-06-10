proc _get_categories() {
	return(array('actions', 'animals', 'easy', 'food_and_cooking', 'hard', 'household_items', 'idioms', 'medium', 'movies', 'other', 'person_or_character', 'travel', 'very_hard', 'songs', 'video_games'));
}

proc _is_match(@guess, @target) {
	// ignore all articles
	@guess = reg_replace('(a|an|the)\\s', '', to_lower(@guess));
	@target = reg_replace('(a|an|the)\\s', '', to_lower(@target));

	// ignore small single spelling errors in targets larger than 4 characters
	if(length(@target) < 6 && @guess == @target
	|| length(@target) > 5 && levenshtein(@guess, @target) < 2) {
		return(true);
	}

	// accept the guess if it contains the entire target phrase
	if(equals_ic(@target, @guess)) {
		return(true);
	}
	return(false);
}

proc _show_matches(@guess, @target) {
	@found = false;
	@modified = '';
	if(length(@guess) == 1) { // if guessing one letter, match the one letter
		@obscured = reg_replace('[a-zA-Z0-9]', '_', @target);
		@target = to_lower(@target);
		@guess = to_lower(@guess);
		while((@pos = string_position(@target, @guess)) > -1) {
			@found = true;
			@modified .= substr(@obscured, 0, @pos).@guess;
			@obscured = substr(@obscured, @pos + 1);
			@target = substr(@target, @pos + 1);
		}
		@modified .= @obscured;
	} else { // else try to match words
		@targetWords = parse_args(@target);
		@guesses = parse_args(@guess);
		foreach(@i: @targetWord in @targetWords) {
			if(array_contains_ic(@guesses, @targetWord)) {
				@found = true;
			} else {
				@targetWords[@i] = reg_replace('[a-zA-Z0-9]', '_', @targetWord);
			}
		}
		@modified = array_implode(@targetWords);
	}
	if(@found) {
		return(@modified);
	} else {
		return(@guess);
	}
}

proc _get_build(@category) {
	@builds = get_value('charades', @category);
	if(!@builds) {
		@availableBuilds = json_decode(read('../data/'.@category.'.json'));
		@builds = associative_array();
		foreach(@b in @availableBuilds) {
			if(is_array(@b)) {
				@build = @b[0];
				@hint = @b[1];
				@builds[@build] = array('count': 0, 'hint': @hint);
			} else {
				@builds[@b] = 0; // number of times used
			}
		}
	}

	// get 3 random builds and pick the one least used
	@randomBuilds = array_rand(@builds, 3);
	@build = '';
	@hint = '';
	@buildCount = 999;
	foreach(@b in @randomBuilds) {
		if(is_array(@builds[@b]) && @builds[@b]['count'] < @buildCount) {
			@build = @b;
			@hint = @builds[@b]['hint'];
			@buildCount = @builds[@b]['count'];
		} else if(!is_array(@builds[@b]) && @builds[@b] < @buildCount) {
			@build = @b;
			@buildCount = @builds[@b];
		}
	}

	if(is_array(@builds[@build])) {
		@builds[@build]['count']++;
	} else {
		@builds[@build]++;
	}
	store_value('charades', @category, @builds);
	return(array('build': @build, 'hint': @hint));
}
