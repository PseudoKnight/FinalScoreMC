proc _get_categories() {
	return(array('easy', 'medium', 'hard', 'very_hard', 'idioms', 'animals', 'people', 'movies', 'tv_shows', 'books'));
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

proc _get_word_from_list(@words, @category) {
	@word = @words[0];
	if(@category == 'books') {
		@word = trimr(split('by', @word)[0]);
	}
	array_remove(@words, 0);
	store_value('charades', @category, @words);
	return(@word);
}

proc _get_word(@closure) {
	@inputMap = array(
		'easy': 'charades_easy',
		'medium': 'charades_moderate',
		'hard': 'charades_hard',
		'very_hard': 'charades_very_hard',
		'idioms': 'idioms_popular',
		'animals': 'animal_names',
		'people': 'people_character_names_popular',
		'movies': 'movie_names_popular',
		'tv_shows': 'tv_show_names_popular',
		'books': 'book_names_popular',
	);
	
	@charades = import('charades');
	@cat = @inputMap[@charades['category']];
	@words = get_value('charades', @charades['category']);
	if(!@words) {
		http_request('http://www.wordgenerator.net/application/p.php?type=1&id='.@cat, array(
			'method': 'GET',
			'success': closure(@response){
				if(!@response['error']) {
					@words = split(',', @response['body']);
					array_remove(@words, array_size(@words) - 1);
					execute(_get_word_from_list(@words, @charades['category']), @closure);
				} else {
					@charades['playersLeft'] = array();
					_end_round(null, null);
				}
			}
		));
	} else {
		execute(_get_word_from_list(@words, @charades['category']), @closure);
	}
}
