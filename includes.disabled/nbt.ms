/*
	Reads in an NBT file and returns a formatted array of the data.

	@filePath The path to the NBT file
 */
array proc _read_nbt_file(string @filePath){

	mixed proc _next_tag(byte_array @ba, int @type){
		switch(@type){
			case 1:
				return(ba_get_byte(@ba));
			case 2:
				return(ba_get_short(@ba));
			case 3:
				return(ba_get_int(@ba));
			case 4:
				return(ba_get_long(@ba));
			case 5:
				return(ba_get_float(@ba));
			case 6:
				return(ba_get_double(@ba));
			case 7:
				return(ba_get_bytes(@ba, ba_get_int(@ba)));
			case 8:
				return(ba_get_string(@ba));
			case 9:
				int @listType = ba_get_byte(@ba);
				int @length = ba_get_int(@ba);
				array @list = array();
				for(@i = 0, @i < @length, @i++){
					@list[] = _next_tag(@ba, @listType);
				}
				return(@list);
			case 10:
				array @compound = associative_array();
				while(true) {
					int @tagType = ba_get_byte(@ba);
					if(@tagType == 0){
						return(@compound);
					}
					string @key = ba_get_string(@ba);
					mixed @value = _next_tag(@ba, @tagType);
					@compound[@key] = @value;
				}
			case 11:
				int @length = ba_get_int(@ba);
				array @intArray = array();
				for(@i = 0, @i < @length, @i++){
					@intArray[] = ba_get_int(@ba);
				}
				return(@intArray);
			case 12:
				int @length = ba_get_int(@ba);
				array @longArray = array();
				for(@i = 0, @i < @length, @i++){
					@longArray[] = ba_get_long(@ba);
				}
				return(@longArray);
		}
		throw('FormatException', 'Encountered invalid NBT type: '.@type);
	}

	byte_array @ba = read_gzip_binary(@filePath);
	@type = ba_get_byte(@ba);
	ba_get_string(@ba);
	return(_next_tag(@ba, @type));
}
