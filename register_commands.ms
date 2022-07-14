/*
	This finds all files ending with *.command, compiles and run them.
	If this occurs during a recompile, it defers this per file by using a queue.
	The primary purpose of this is to limit blocking recompile time on a live server.
	Commands that cannot be deferred should not use *.command suffixes.
*/

void proc _include_command(string @file, boolean @recompile = import('recompile')) {
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

int proc _find_commands(string @parent = '.') {
	int @count = 0;
	foreach(string @file in list_files(@parent)) {
		@path = @parent.'/'.@file;
		if(is_dir(@path)) {
			if(string_position(@file, '.disabled') < 0 && string_position(@file, '.library') < 0) {
				@count += _find_commands(@path);
			}
		} else if(string_ends_with(@file, '.command')) {
			@count++;
			_include_command(@path);
		}
	}
	return(@count);
}

queue_push(iclosure(int @count = _find_commands()) {
	msg(@count.' command files processed.');
});