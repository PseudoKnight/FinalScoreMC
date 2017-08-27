proc _get_categories() {
	return(array('actions', 'animals', 'easy', 'food_and_cooking', 'food', 'hard', 'household_items', 'idioms', 'medium', 'movies', 'other', 'people_and_characters', 'places', 'travel', 'very_hard'));
}

proc _get_match(@one, @two) {
	// ignore beginning articles
	@one = reg_replace('^(a|the)\\s', '', to_lower(@one));
	@two = reg_replace('^(a|the)\\s', '', to_lower(@two));
	
	// ignore single spelling errors
	if(levenshtein(@one, @two) < 2) {
		return(2);
	}
	
	// it's not a match, but let's check if they got one word right
	@words = parse_args(@one);
	foreach(@word in @words) {
		if(length(@word) > 3 && string_position(@two, @word) >= 0) {
			return(1);
		}
	}
	
	return(0);
}

proc _get_word(@category) {
	@words = get_value('charades', @category);
	if(!@words) {
		@wordArray = json_decode(read('../data/'.@category.'.json'));
		@words = associative_array();
		foreach(@word in @wordArray) {
			@words[@word] = 0;
		}
	}
	@count = 0;
	@word = null;
	do {
		@word = array_index(@words, @count);
	} while(is_null(@word));
	@words[@word]++;
	store_value('charades', @category, @words);
	return(@word);
}
