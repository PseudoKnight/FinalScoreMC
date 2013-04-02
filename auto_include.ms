proc(_relative, @loc, @dir,
  switch(@dir
  , 'up',
    return(array(@loc[0], @loc[1] + 1, @loc[2], @loc[3]))
  , 'down',
    return(array(@loc[0], @loc[1] - 1, @loc[2], @loc[3]))
  , 'north',
    return(array(@loc[0], @loc[1], @loc[2] - 1, @loc[3]))
  , 'south',
    return(array(@loc[0], @loc[1], @loc[2] + 1, @loc[3]))
  , 'east',
    return(array(@loc[0] + 1, @loc[1], @loc[2], @loc[3]))
  , 'west',
    return(array(@loc[0] - 1, @loc[1], @loc[2], @loc[3]))
  , 
    console('Cannot get relative block '.@dir.' from '.@loc.'.')
    return(@loc)
  )
)

proc(_clear_pinv, assign(@player, player()),
  set_pinv(@player, array(0: null, 1: null, 2: null, 3: null, 4: null, 5: null, 6: null, 7: null, 8: null, 9: null, 10: null, 11: null, 12: null, 13: null, 14: null, 15: null, 16: null, 17: null, 18: null, 19: null, 20: null, 21: null, 22: null, 23: null, 24: null, 25: null, 26: null, 27: null, 28: null, 29: null, 30: null, 31: null, 32: null, 33: null, 34: null, 35: null, 100: null, 101: null, 102: null, 103: null))
)

proc(_cooldown, @from, @length,
  if((time() - @from) / 1000 > @length) {
    return(true)
  } else {
    return(false)
  }
)

#pgive_item replacement
proc(_pgive_item, @player, @item,
  for(@i = 0, @i < 36, @i++,
    if(pinv(@player, @i) == null || (pinv(@player, @i)['type'] == @item['type'] && pinv(@player, @i)['data'] == @item['data'] && (pinv(@player, @i)['qty'] + @item['qty']) <= max_stack_size(@item))) {
      if(pinv(@player, @i) != null, array_set(@item, 'qty', @item['qty'] + pinv(@player, @i)['qty']))
      @inv = array()
      array_set(@inv, @i, @item)
      set_pinv(@player, @inv)
      return(true)
    }
  )
  return(false)
)

# proc(_fill_inventory, @loc,
  # for(@i = 0, @i < get_inventory_size(@loc), @i++,
    # @item = get_inventory_item(@loc, @i)
    # if(@item != null) {
      # @item['qty'] = 64
      # set_inventory_item(@loc, @i, @item)
    # }
  # )
# )

# Removes all DROPPED_ITEM entities from region.
# Since this loads entities by chunks it has a loose entity selection
proc(_remove_region_items, @region,
  if(!sk_region_exists(@region)) {
    console('Can\'t remove dropped items because region doesn\'t exist: '.@region)
    return(false)
  }
  @loc = sk_region_info(@region, pworld())[0]
  if(array_size(@loc) > 2) {
    console('Can\'t remove dropped items because region isn\'t a cuboid: '.@region)
    return(false)
  }
  for(@x = @loc[1][0], @x < (@loc[0][0] + 15), inc(@x, 16),
    if(@x > @loc[0][0], @x = @loc[0][0])
    for(@z = @loc[1][2], @z < (@loc[0][2] + 15), inc(@z, 16),
      if(@z > @loc[0][2], @z = @loc[0][2])
      foreach(all_entities(array(@x, 64, @z, pworld())), @entity,
        if(entity_type(@entity) == 'DROPPED_ITEM') {
          entity_remove(@entity)
        }
      )
    )
  )
  return(true)
)

# Returns the total qty of space available
# @item: accepts item array with 'type' and 'data'
# proc(_pitem_space, @player, @item,
  # @stack = max_stack_size(@item)
  # @space = 0
  # for(@i = 0, @i < 36, @i++,
    # if(pinv(@player, @i) == null) {
      # @space += @stack
    # } else if(pinv(@player, @i)['type'] == @item['type'] && pinv(@player, @i)['data'] == @item['data']) {
      # @space += @stack - pinv(@player, @i)['qty']
    # }
  # )
  # return(@space)
# )


# Remove all potion effects from a player
proc(_remove_peffects, @player,
  @effects = get_peffect(@player)
  foreach(@effects, @effect,
    set_peffect(@player, @effect['id'], 0, 0)
  )
)

proc(_shop_item, @signtext,
  @item = reg_match('\\[([\\w\\s]+)(?::([0-9]{1,4}))?\\]', @signtext)
  if(array_size(@item) < 2, die())
  if(is_numeric(@item[1])) {
    if(@item[2] != null) {
      @itemid = @item[1].'.'.@item[2]
    } else {
      @itemid = @item[1]
    }
  } else {
    if(@item[2] != null) {
      @itemid = reg_split('\\:', data_values(@item[1]))[0].'.'.@item[2]
    } else {
      @itemid = reg_replace(':', '.', data_values(@item[1]))
      if(@itemid == null, die())
    }
  }
  return(@itemid)
)

#color display name
proc(_colorname, assign(@player, player()),
  ifelse(has_permission(@player, 'group.moderators'),
    @color = 'aqua',
    has_permission(@player, 'group.builders'),
    @color = 'gold',
    has_permission(@player, 'group.donors'),
    @color = 'green',
    has_permission(@player, 'group.everyone'),
    @color = 'yellow',
    @color = 'white'
  )
  return(color(@color))
)

#returns world alias when given world folder name
proc(_worldname, @world,
  @worlds = array('world': 'Alpha', 'world_nether': 'Alpha Nether', 'world3': 'Delta', 'world3_nether': 'Delta Nether', 'world4': 'Gamma', 'world4_nether': 'Gamma Nether', 'world_the_end': 'The End', 'custom': 'Custom', 'dev': 'Dev', 'outworld': 'Outworld')
  if(array_index_exists(@worlds, to_lower(@world))) { 
    return(@worlds[to_lower(@world)])
  } else {
    return(to_lower(@world))
  }
)

#returns world folder name when given world alias
proc(_worldid, @world,
  @worlds = array('alpha': 'world', 'alphanether': 'world_nether', 'delta': 'world3', 'deltanether': 'world3_nether', 'gamma': 'world4', 'gammanether': 'world4_nether', 'theend': 'world_the_end', 'custom': 'custom', 'dev': 'dev', 'outworld': 'outworld')
  if(array_index_exists(@worlds, to_lower(@world))) { 
    return(@worlds[to_lower(@world)])
  } else {
    return(to_lower(@world))
  }
)

#Warms up a tp with effects and configurable timer
proc(_warmuptp, @length, @player, @loc, assign(@yaw, null), assign(@pitch, null),
  set_peffect(@player, 9, 1, 7)
  play_sound(ploc(@player), array('sound': 'PORTAL_TRIGGER', 'volume': 1, 'pitch': 1))
  set_timeout(round(@length * 1000), closure(
    if(!ponline(@player), die())
    make_effect(ploc(@player), 'GHAST_SHOOT', 20)
    make_effect(ploc(@player), 'MOBSPAWNER_FLAMES', 20)
    if(@yaw != null && @pitch != null) {
      pfacing(@player, @yaw, @pitch)
    }
    set_ploc(@player, @loc)
    set_peffect(@player, 15, 1, 1)
    make_effect(@loc, 'GHAST_SHOOT', 20)
    make_effect(@loc, 'MOBSPAWNER_FLAMES', 20)
  ))
)

#Messsages every player within the specified region
proc(_regionmsg, @region, @msg,
  foreach(all_players(), @player,
    if(array_contains(sk_current_regions(@player), @region)) {
      tmsg(@player, @msg)
    }
  )
)

#Messsages every player within the specified world
proc(_worldmsg, @world, @msg,
  foreach(all_players(), @player,
    if(pworld(@player) == @world) {
      tmsg(@player, @msg)
    }
  )
)

#get qty of specific item in chest
proc(_get_inventory_count, @loc, @item,
  try(@size = get_inventory_size(@loc), return(null))
  if(is_numeric(@item), @item = @item.':0')
  @count = 0
  for(@i = 0, @i < @size, @i++,
    if(is_null(assign(@slot, get_inventory_item(@loc, @i))), continue())
    if(@slot['type'].':'.@slot['data'] == @item || @item == 'all') {
      @count = @count + @slot['qty']
    }
  )
  return(@count) 
)

# Since CommandHelper doesn't do this for us, I have to manually check to see if you can build.
# It doesn't respect: PARENTS, GROUPS, FLAGS
# __global__ regions are hard-coded for 'custom' and 'dev' worlds.
# proc(_can_build, @loc, assign(@player, player()),
  # if(has_permission(@player, 'worldguard.region.bypass.'.pworld(@player)), return(true))
  # @canbuild = true
  # # special handling for dev & custom worlds
  # if((pworld(@player) == 'custom' && !array_contains(pgroup(@player), 'moderators')) || (pworld(@player) == 'dev' && !array_contains(pgroup(@player), 'engineers'))) {
    # @canbuild = false
  # }
  # # default to false if there are any regions
  # if(array_size(sk_regions_at(@loc)) > 0) {
    # @canbuild = false
  # }
  # @highestpriority = -1
  # # iterate through all applicable regions and respect higher priorities
  # foreach(sk_regions_at(@loc), @region,
    # if(sk_region_info(@region, pworld(@player))[4] < @highestpriority, continue())
    # ifelse(!array_contains_ic(sk_region_info(@region, pworld(@player))[1], @player) && !array_contains_ic(sk_region_info(@region, pworld(@player))[2], @player),
      # @canbuild = false,
    # sk_region_info(@region, pworld(@player))[4] > @highestpriority,
      # @canbuild = true
    # )
    # @highestpriority = sk_region_info(@region, pworld(@player))[4]
  # )
  # return(@canbuild)
# )

# Populate multiple signs with an array_size larger than 4
# proc(_populate_signs, @locarray, @textarray, assign(@offset, 0),
  # for(@i = 0, @i < array_size(@locarray), @i++,
    # set_sign_text(@locarray[@i], @textarray[cslice((@i * 4) + @offset, (@i * 4) + 3 + @offset)])
  # )
# )

#Returns the distance between two blocks, or any other 3d points, for that matter
proc(_3d_distance, @arr1, @arr2,
  return(floor(sqrt(((@arr2[0] - @arr1[0]) ** 2) + ((@arr2[1] - @arr1[1]) ** 2) + ((@arr2[2] - @arr1[2]) ** 2))))
)

proc(_horizontal_distance, @loc1, @loc2,
  return(max(sqrt((@loc1[0] - @loc2[0]) ** 2), sqrt((@loc1[2] - @loc2[2]) ** 2)))
)

#Given two blocks, iterates through all the blocks inside the cuboid, and calls the 
#user defined function on them. The used defined procedure should accept 3 parameters,
#the x, y, and z coordinates of the block.
proc(_iterate_cuboid, @b1, @b2, @proc_name,
  for(@x = min(@b1[0], @b2[0]), @x <= max(@b1[0], @b2[0]), @x++,
    for(@y = min(@b1[1], @b2[1]), @y <= max(@b1[1], @b2[1]), @y++,
      for(@z = min(@b1[2], @b2[2]), @z <= max(@b1[2], @b2[2]), @z++,
        call_proc(@proc_name, @x, @y, @z)
      )
    )
  )
)
