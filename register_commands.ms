/*
	This finds all files ending with *.command, compiles and run them.
	If this occurs during a recompile, it defers this per file by using a queue.
	The primary purpose of this is to limit blocking recompile time on a live server.
	Commands that cannot be deferred should not use *.command suffixes.
*/

proc _include_command(@file, @recompile = import('recompile')) {
	@closure = closure() {
		try {
			include(@file);
		} catch(IncludeException @ex) {
			console(@ex['message'], false);
		}
	}
	if(@recompile) {
		queue_push(@closure);
	} else {
		execute(@closure);
	}
}

proc _find_commands(@parent = '.') {
	foreach(@file in list_files(@parent)) {
		@path = @parent.'/'.@file;
		if(is_dir(@path)) {
			if(string_position(@file, '.disabled') < 0 && string_position(@file, '.library') < 0) {
				_find_commands(@path);
			}
		} else if(string_ends_with(@file, '.command')) {
			_include_command(@path);
		}
	}
}

_find_commands();