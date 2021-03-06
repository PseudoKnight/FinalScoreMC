proc _get_categories() {
	return(array('actions', 'animals', 'easy', 'food_and_cooking', 'hard', 'household_items', 'idioms', 'medium', 'movies', 'other', 'person_or_character', 'travel', 'very_hard', 'songs', 'video_games'));
}

proc _get_match(@guess, @target) {
	// ignore beginning articles
	@guess = reg_replace('^(a|the)\\s', '', to_lower(@guess));
	@target = reg_replace('^(a|the)\\s', '', to_lower(@target));

	// ignore small single spelling errors in targets larger than 4 characters
	if(length(@target) < 5 && @guess == @target
	|| length(@target) > 4 && levenshtein(@guess, @target) < 2) {
		return(true);
	}

	// accept the guess if it contains the entire target phrase
	if(equals_ic(@target, @guess)) {
		return(true);
	}
	return(false);
}

proc _highlight_similarities(@guess, @target) {
	@words = parse_args(@guess);
	foreach(@index: @word in @words) {
		if(length(@word) > 1 && reg_match('(?i)'.@word, @target)) {
			@words[@index] = color('bold').@word;
		} else {
			@words[@index] = color('reset').@word;
		}
	}
	return(array_implode(@words));
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
