@recompile = import('recompile');
foreach(@directory in list_files('.')) {
	if(is_dir(@directory)) {
		@base = @directory.'/command.library';
		if(file_exists(@base)) {
			@includeAllFiles = closure(){
				foreach(@file in list_files(@base)) {
					include(@base.'/'.@file);
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
