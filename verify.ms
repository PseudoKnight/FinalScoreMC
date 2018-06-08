/*
	This is a script that can be used in your script editor to verify the files for errors.
	It uses the CommandHelper "verify" commandline mode.
*/
if(array_size(@arguments) == 0 || string_ends_with(@arguments[0], 'verify.ms')) {
	die();
}
try {
	include(@arguments[0]);
} catch(Exception @ex) {
	@lines = split('\n', @ex['message'])[1..-1];
	foreach(@line in @lines) {
		if(!string_contains(@line, 'does not exist in the Java Interpreter')) {
			msg(@line);
		}
	}
}
