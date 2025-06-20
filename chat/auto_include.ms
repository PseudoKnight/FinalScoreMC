/*
	Returns a Minecraft color code for the specified player's group
*/
proc _colorname(@player) {
	if(!@player) {
		@player = player();
	}
	try {
		@group = _pdata(@player)['group'];
		switch(@group) {
			case 'admin':
			case 'moderator':
				return(color('AQUA'));
			case 'donor':
				return(color('GREEN'));
			case 'engineer':
			case 'builder':
				return(color('GOLD'));
			case 'regular':
			case 'member':
				return(color('YELLOW'));
		}
	} catch(IndexOverflowException @ex) {
		// No group
	}
	return(color('WHITE'));
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
		'{': 4,
		'}': 4,
		'*': 4,
		'>': 5,
		'<': 5,
		'f': 5,
		'k': 5,
		'~': 7,
		'@': 7,
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
	if(@remainingWidth < 1) {
		return(replace(@string, @replaceChar, ''));
	}
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

/*
	Constructs and sends a tellraw command with a hover event
*/
proc _tellraw(@recipients, @components) {
	proc _colorize(@text) {
		@colors = array(
			'&0': '"color":"black",',
			'&1': '"color":"dark_blue",',
			'&2': '"color":"dark_green",',
			'&3': '"color":"dark_aqua",',
			'&4': '"color":"dark_red",',
			'&5': '"color":"dark_purple",',
			'&6': '"color":"gold",',
			'&7': '"color":"gray",',
			'&8': '"color":"dark_gray",',
			'&9': '"color":"blue",',
			'&a': '"color":"green",',
			'&b': '"color":"aqua",',
			'&c': '"color":"red",',
			'&d': '"color":"light_purple",',
			'&e': '"color":"yellow",',
			'&f': '"color":"white",',
			'&k': '"obfuscated":true,',
			'&l': '"bold":true,',
			'&m': '"strikethrough":true,',
			'&n': '"underlined":true,',
			'&o': '"italic":true,',
			'&r': '',
			'': '',
		);
		@matches = reg_match_all('(&[0-9a-fk-or]|&#[0-9a-f]{6})?(&[k-o])?(&[k-o])?(&[k-o])?((?:&[^0-9a-fk-or#]|[^&])*)', @text);
		@raw = '';
		foreach(@m in @matches) {
			if(@m[0]) {
				@c = array_get(@colors, @m[1], '"color":"'.@m[1][1..-1].'",');
				@raw .= ',{'.@c.@colors[@m[2]].@colors[@m[3]].@colors[@m[4]].'"text":"'.@m[5].'"}';
			}
		}
		return(@raw);
	}
	
	@raw = ' [""';
	foreach(@c in @components) {
		if(!is_array(@c)) {
			@parts = reg_match('(.*?)(?:https?://|www\\.)([^/\\s]+)([^\\s]*)(.*)', @c);
			if(@parts) {
				@raw .= _colorize(@parts[1])
						.',{"color":"aqua","text":"\u29C9'.@parts[2].'","clickEvent":{"action":"open_url","value":"http://'
						.@parts[2].@parts[3].'"},"hoverEvent":{"action":"show_text","value":"http://'.@parts[2].@parts[3].'"}}'
						._colorize(@parts[4]);
			} else {
				@raw .= _colorize(@c);
			}
		} else {
			switch(@c[0]) {
				case "open_url":
					@raw .= ',{"color":"aqua","text":"\u29C9'.@c[1].'","clickEvent":{"action":"open_url","value":"'.@c[2]
							.'"},"hoverEvent":{"action":"show_text","value":"'.@c[3].'"}}';
				case 'hover':
					@raw .= ',{"text":"'.colorize(@c[1]).'","hoverEvent":{"action":"show_text","value":"'.colorize(@c[2]).'"}}';
				case 'colorize':
					@raw .= ',"'.colorize(@c[1]).'"';
				case 'plain':
					@raw .= ',"'.@c[1].'"';
			}
		}
	}
	@raw .= ']';
	foreach(@player in @recipients) {
		runas('~console', '/tellraw '.@player.@raw);
	}
}

/*
	Capitalizes every separated word.
 */
proc _to_upper_camel_case(@string) {
	@split = reg_split('[_\\s]', @string);
	foreach(@i: @s in @split) {
		@split[@i] = to_upper(@s[0]).to_lower(@s[1..]);
	}
	return(array_implode(@split));
}

/*
	Broadcast to all places.
	Broadcasts as-is to chat, but will be formatted for other outputs like actions.
 */
proc _broadcast(@msg) {
	broadcast(@msg);
	@msg = strip_colors(@msg);
	if(function_exists('discord_broadcast')) {
		discord_broadcast('minecraft_chat', array(embed: array(title: @msg)));
	}
	if(function_exists('dm_broadcast_to_web')) {
		dm_broadcast_to_web('* '.@msg);
	}
}

/*
	Returns a timestamp chat prefix using the server's timezone.
 */
proc _timestamp() {
	return(color('dark_gray').simple_date('h:mm', time(), 'US/Central').' ');
}
