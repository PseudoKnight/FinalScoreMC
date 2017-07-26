foreach(@directory in list_files('.')) {
	if(is_dir(@directory)) {
		@base = @directory.'/command.library';
		if(file_exists(@base)) {
			queue_push(closure(){
				foreach(@file in list_files(@base)) {
					include(@base.'/'.@file);
				}
			});
		}
	}
}
