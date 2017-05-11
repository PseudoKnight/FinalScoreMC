/*
	Returns a Minecraft color code for the specified player's group
*/
proc _colorname(@player) {
	if(!@player) {
		@player = player();
	}
	if(has_permission(@player, 'group.moderator')) {
		return(color('AQUA'));
	} else if(has_permission(@player, 'group.donor')) {
		return(color('GREEN'));
	} else if(has_permission(@player, 'group.builder')) {
		return(color('GOLD'));
	} else if(has_permission(@player, 'group.member')) {
		return(color('YELLOW'));
	}
}

/*
	Messsages every player within a WorldGuard region
*/
proc _regionmsg(@region, @msg) {
	foreach(@player in all_players()) {
		if(ponline(@player)
		&& array_contains(sk_current_regions(@player), @region)) {
			tmsg(@player, @msg);
		}
	}
}

/*
	Messsages every player within a world
*/
proc _worldmsg(@world, @msg) {
	foreach(@player in all_players(@world)) {
		if(ponline(@player)) { // sometimes player will be offline here
			tmsg(@player, @msg);
		}
	}
}

/*
	Returns the character width map
*/
proc _char_width() {
	# Thanks to Octopod for this list
	return(associative_array(
		',': 2,
		'!': 2,
		':': 2,
		'i': 2,
		'|': 2,
		'.': 2,
		'`': 3,
		'\'': 3,
		'l': 3,
		'[': 4,
		']': 4,
		' ': 4,
		'I': 4,
		't': 4,
		'*': 5,
		'>': 5,
		'<': 5,
		'{': 5,
		'}': 5,
		'f': 5,
		'k': 5,
	));
}

/*
	Returns the pixel width of the string
*/
proc _string_width(@string) {
	@width = 0;
	@bold = 0;
	@chars = _char_width();
	foreach(@i: @c in @string) {
		if(@c === '\u00a7') {
			if(@string[@i + 1] === 'l') {
				@bold = 1;
			} else if(reg_match('[0-9a-fr]', @string[@i + 1])) {
				@bold = 0;
			}
			continue(2);
		}
		if(array_index_exists(@chars, @c)) {
			@width += @chars[@c] + @bold;
		} else {
			@width += 6 + @bold;
		}
	}
	return(@width);
}

/*
	Fills a string evenly with a character so that it extends to a full line
*/
proc _fill_string(@replaceChar, @fillChar, @string, @lineWidth = 320) {
	@width = _string_width(replace(@string, @replaceChar, ''));
	@fillCount = reg_count('\\'.@replaceChar, @string);

	@remainingWidth = @lineWidth - @width;
	@charWidth = 6;
	@chars = _char_width();
	if(array_index_exists(@chars, @fillChar)) {
		@charWidth = @chars[@fillChar];
	}

	@fillWidth = floor(@remainingWidth / @charWidth / @fillCount);
	return(replace(@string, @replaceChar, string_multiply(@fillChar, @fillWidth)));
}

/*
	Takes a string and returns an array of strings of the specified width.
	This will not split words.
*/
proc _wrap_string(@string, @width = 320) {
	@words = split(' ', @string);
	@lines = array();
	@linewidth = 0;
	@line = '';
	foreach(@word in @words) {
		@wordwidth = _string_width(@word);
		@linewidth += @wordwidth;
		if(@linewidth + 3 < @width) {
			if(length(@line) > 0) {
				@linewidth += 3;
				@line .= ' '.@word;
			} else {
				@line .= @word;
			}
		} else {
			@lines[] = @line;
			@linewidth = @wordwidth;
			@line = @word;
		}
	}
	@lines[] = @line;
	return(@lines);
}

/*
 	Returns a filtered array of strings with only those that start with the given case-insensitive characters
*/
proc _strings_start_with_ic(@strings, @chars) {
	return(array_filter(@strings, closure(@index, @string) {
		return(length(@chars) <= length(@string) && equals_ic(@chars, substr(@string, 0, length(@chars))));
	}));
}

/*
	Create clickable commands for a JSON message
*/
proc _click_tell(@recipients, @components) {
	@message = ' [""';
	foreach(@c in @components) {
		@message .= ',{"text":"';
		if(!is_array(@c)) {
			@message .= colorize(@c).'"}';
		} else {
			@message .= colorize(@c[0]).'","clickEvent":{"action":"run_command","value":"'.@c[1].'"}}';
		}
	}
	@message .= ']';
	foreach(@player in @recipients) {
		runas('~console', '/tellraw '.@player.@message);
	}
}
