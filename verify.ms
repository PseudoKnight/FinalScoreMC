/*
	This is a script that can be used in your script editor to verify the files for errors.
	It uses the CommandHelper "verify" commandline mode.
*/
try {
	if(array_size(@arguments) == 0) {
		die();
	}
	@file = @arguments[0];
	if(string_ends_with(@file, 'verify.ms')) {
		die();
	}

	@file = replace(@arguments[0], '\\', '\\\\');
	@result = shell('java -jar C:/commandhelper/commandhelper-3.3.4-SNAPSHOT-full.jar verify '.@file);
	if(@result) {
		@errors = json_decode(@result);
		foreach(@error in @errors) {
			if(!string_starts_with(@error['msg'], 'The function ')) {
				msg(@error['msg'].' : line '.@error['line']);
			}
		}
	}
} catch(Exception @ex) {
	msg('Experienced an exception in verify.ms: '. @ex);
}
