# Script: Function Documentation
# Author: LewsTherin

# /doc - List all known extensions, including builtins.
# /doc <extensionname> - List all functions in a given extension.
# /doc <func>[,func] [func] - List specific functions.
register_command('doc', array(
	'description': 'Output colorful information about extensions and functions.',
	'usage': '/doc <function_name>',
	'permission': 'command.doc',
	'tabcompleter': closure(@alias, @sender, @args, @info) {
		return(array());
	},
	'executor': closure(@alias, @sender, @args, @info) {
		proc _get_closest(@name, @list) {
			# Search an array for a matching entry, regardless of case, and return it.
			foreach(@ext in @list) {
				if (to_lower(@ext) == to_lower(@name)) {
					return(@ext);
				}
			}
			return(null);
		}

		proc _desc_func(@func) {
			# Colorfully describe a function.
			try {
				@desc = reflect_docs(@func, 'description');
				@returns = reflect_docs(@func, 'type');
				@args = reflect_docs(@func, 'args');

				msg(color('YELLOW') . @func . ':' color('GREEN') . 'Returns' @returns .
				'.' color('BLUE') . 'Expects' @args . '.' color('YELLOW') . @desc);
			} catch(FormatException @ex) {
				msg(color('RED') . 'Could not show information for' @func);
			}
		}

		if (!@args) {
			# List known extensions.
			@extensions = array_keys(extension_info());
			if (@extensions) {
				msg(color('BLUE') . 'Installed extensions:');
				foreach (@extension in @extensions) {
					msg(color('RED') . ' - ' . color('GREEN') . @extension);
				}
			} else {
				msg(color('RED') . 'No extensions installed!');
			}
		} else {
			# Show functions in a given extension.
			@extensions = extension_info();

			# Get extension name regardless of case.
			@extension = _get_closest(@args[0], array_keys(@extensions));

			if (@extension) {
				@extension = @extensions[@extension];
				@functions = @extension['functions'];

				foreach (@function in @functions) {
					_desc_func(@function);
				}
			} else {
				while(@args) {
					@many = split(',', array_remove(@args, 0))
					foreach (@function in @many) {
						# Get function name regardless of case.
						@functionname = to_lower(@function);
						_desc_func(@functionname);
					}
				}
			}
		}
	}
));
