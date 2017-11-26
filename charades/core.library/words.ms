proc _get_categories() {
	return(array('actions', 'animals', 'easy', 'food_and_cooking', 'hard', 'household_items', 'idioms', 'medium', 'movies', 'other', 'people_and_characters', 'travel', 'very_hard', 'finalscoremc'));
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
}

proc _highlight_similarities(@guess, @target) {
	@words = parse_args(@guess);
	foreach(@index: @word in @words) {
		if(length(@word) > 1 && string_position(@target, @word) >= 0) {
			@words[@index] = color('bold').@word;
		} else {
			@words[@index] = color('reset').@word;
		}
	}
	return(array_implode(@words));
}

proc _get_word(@category) {
	@words = get_value('charades', @category);
	if(!@words) {
		@wordArray = json_decode(read('../data/'.@category.'.json'));
		@words = associative_array();
		foreach(@w in @wordArray) {
			@words[@w] = 0; // number of times used
		}
	}
	
	// get 3 random words and pick the one least used
	@randomWords = array_rand(@words, 3);
	@word = '';
	@wordCount = 999;
	foreach(@w in @randomWords) {
		if(@words[@w] < @wordCount) {
			@word = @w;
			@wordCount = @words[@w];
		}
	}
	
	@words[@word]++;
	store_value('charades', @category, @words);
	return(@word);
}
