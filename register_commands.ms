@recompile = import('recompile');
foreach(@directory in list_files('.')) {
	if(is_dir(@directory)) {
		foreach(@subdirectory in list_files(@directory)) {
			@library = @directory.'/'.@subdirectory;
			if(@subdirectory == 'command.library'
			|| is_dir(@library) && file_exists(@library .= '/command.library')) {
				@includeAllFiles = closure(){
					foreach(@file in list_files(@library)) {
						if(is_file(@file)) {
							include(@library.'/'.@file);
						}
					}
				}
				if(@recompile) {
					queue_push(@includeAllFiles);
				} else {
					execute(@includeAllFiles);
				}
			}
		}
	}
}
