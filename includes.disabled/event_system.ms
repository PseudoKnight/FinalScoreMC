/*
	Registers an event listener with a closure that executes whenever _trigger_event()
	is called for that event. An associative array is passed to the closure.
	Unlike bind(), all event data is mutable, so any modifications to the array reference
	in the closure are seen by subsequent listeners and the code following the event trigger.

	@eventName an arbitrary string used to trigger an event
	@id used for unregistering the listener later
	@priority an int used to sort listener execution order, low to high
	@closure executed on event trigger and accepts an associative array argument of event data
 */
void proc _register_listener(string @eventName, string @id, int @priority, closure @closure){
	_unregister_listener(@eventName, @id);
	array @listeners = import('event.'.@eventName, array());
	@listeners[] = array(id: @id, priority: @priority, closure: @closure);
	array_sort(@listeners, closure(@left, @right) {
		return(@left['priority'] > @right['priority']);
	});
	export('event.'.@eventName, @listeners);
}

/*
	Unregisters an event listener with the specified id.

	@eventName an arbitrary string used to trigger an event
	@id from when the listener was registered
 */
void proc _unregister_listener(string @eventName, string @id){
	array @listeners = import('event.'.@eventName, array());
	foreach(@index: @listener in @listeners) {
		if(@listener['id'] == @id) {
			array_remove(@listeners, @index);
			return();
		}
	}
}

/*
	Executes all listeners for an event of the given name.
	The array key 'cancelled' is added to the event data.

	@eventName an arbitrary string used to trigger an event
	@data is the associative array of event data
 */
void proc _trigger_event(string @eventName, array @data){
	@data['cancelled'] = false;
	array @listeners = import('event.'.@eventName, array());
	foreach(@listener in @listeners){
		try {
			execute(@data, @listener['closure']);
			if(@data['cancelled']) {
				break();
			}
		} catch(Exception @ex) {
			console(split('.', @ex['classType'])[-1].': '.@ex['message']);
			foreach(@trace in @ex['stackTrace']) {
				console(split('LocalPackages', @trace['file'])[-1].':'.@trace['line'].' '.@trace['id']);
			}
		}
	}
}