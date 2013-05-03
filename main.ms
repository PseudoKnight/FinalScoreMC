#prime variables
@requests = get_value('session.requests')
if(!@requests, @requests = array(), clear_value('session.requests'))
export(@requests)
@conv = get_value('session.conv')
if(!@conv, @conv = array(), clear_value('session.conv'))
export(@conv)
@stopwatch = get_value('session.stopwatch')
if(!@stopwatch, @stopwatch = array(), clear_value('session.stopwatch'))
export(@stopwatch)
@ignorelist = array()
export(@ignorelist)

set_world_time('dev', 700)
set_interval(9 * 60 * 1000, closure(
  runas('~console', '/save-all')
  set_world_time('dev', 700)
))

bind('player_login', null, null, @event,
  if(get_server_info(10)) {
    if(@event['result'] != 'ALLOWED', die())
    @info = get_value('player.'.@event['player'])
    if(!@info, @info = array('ips': array()))
    if(!array_contains(@info['ips'], @event['ip'])) {
      array_push(@info['ips'], @event['ip'])
      if(array_size(@info['ips']) > 3) {
        array_remove(@info['ips'], 0)
      }
      store_value('player.'.@event['player'], @info)
    }
  } else {
    @ips = get_value('player.'.@event['player'])['ips']
    if(!array_contains(@ips, @event['ip'])) {
      console(@event['player'].': '.@event['ip'].', '.@ips)
      modify_event('result', 'KICK_OTHER')
      modify_event('kickmsg', 'Minecraft auth servers are down and your IP doesn\'t match our records.')
    }
  }
)

# Player join messages and tab list colors
bind('player_join', null, null, @event,
set_timeout(250, closure(assign(@loc, ploc()),
  #anti-cheat codes
  msg('\u00A7f \u00A7f \u00A71 \u00A70 \u00A72 \u00A74 \u00A7f \u00A7f \u00A72 \u00A70 \u00A74 \u00A78 \u00A73 \u00A79 \u00A72 \u00A70 \u00A70 \u00A70 \u00A70\u00A70\u00A71\u00A72\u00A73\u00A74\u00A75\u00A76\u00A77\u00A78\u00A7f\u00A7e')
  #Welcome messages
  msg(color(1).color(l).'--------------------')
  msg(color('gold'), color(l), '\u2302', color('red'), color('l'), '\u2302', color('aqua'), color(l), '\u2302', color('dark_red'), color('l'), '\u2302', color('gold'), color('l'), ' FINALSCORE ', color('yellow'), color('l'), '\u00AB', color(r), ' \u25AA \u25AA \u25AA')
  msg(color(1).color(l).'--------------------')
  msg(get_value('motd'))
  #Tab list colors
  if(length(player()) > 14) {
    set_list_name(_colorname().substr(player(), 0, 14))
  } else {
    set_list_name(_colorname().player())
  }
  # orphaned players are players left on deleted worlds
  @orphaned = get_value('orphaned')
  if(array_contains(@orphaned, player())) {
    @loc = get_spawn('world')
    set_ploc(@loc)
    array_remove_values(@orphaned, player())
    store_value('orphaned', @orphaned)
  }
  set_timeout(800, closure(
    if(@loc[1] > ploc()[1]) {
      set_ploc(@loc)
    }
  ))
))
)

# Teleport protection from falling through blocks
bind('player_teleport', null, null, @event,
  if(@event['to']['3'] != @event['from']['3']
    || _horizontal_distance(@event['to'], @event['from']) > 112) {
    set_timeout(450, closure(
      if((@event['to'][1] - 1) > ploc()[1])
      {
        set_ploc(array(@event['to'][0], @event['to'][1] - 1, @event['to'][2], @event['to'][3]))
        console('Adjusted '.player().'\'s location after teleport.')
      }
    ))
  }
)

bind('player_death', null, null, @event,
  if(!array_contains(array('custom', 'dev'), pworld())) {
    @log = @event['player'].' died @ '.round(@event['location'][0]).','.round(@event['location'][1]).','.round(@event['location'][2]).' on '.@event['location'][3].', dropping '.@event['xp'].'xp and '
    foreach(@event['drops'], @drop,
      if(is_array(@drop)) {
        @log .= if(@drop['qty'] > 1, @drop['qty']).' '.data_name(@drop['type']).if(@drop['data'] > 0, ':'.@drop['data']).' '.if(array_size(@drop['enchants']) > 0, 'with '.@drop['enchants']. 'enchants').' - '
      }
    )
    console(@log, false)
    msg('You died @ ', round(@event['location'][0]), ',', round(@event['location'][1]), ',', round(@event['location'][2]))
  } else {
    modify_event('death_message', null)
  }
)

# Outworld message
bind('world_changed', null, array('to': 'outworld'), @event,
  if(!array_contains(array('outworld_nether', 'outworld', 'outworld_the_end'), @event['from'])) {
    msg(color('k').'XX'.color('r').color('gold').color('bold').' Welcome to the outworld! '.color('r').color('k').'XX\n'
    .color('red').'This is a temporary world. Do not build or store anything permanent.')
  }
)

# Log commands
bind('player_command', null, null, @event,
  if(is_alias(@event['command'])) {
    console(@event['player'].' ran: '.@event['command'], false)
  }
)

# PMs, ignores, and mutes
bind('player_chat', null, null, @event,
  if(@event['message'] == '-') {
    cancel()
    die()
  }
  if(@event['message'][0] == '@') {
    @p = substr(parse_args(@event['message'])[0], 1)
    try(@player = player(@p),
      cancel()
      die('Player not found.')
    )
    if((length(@p) + 2) >= length(@event['message'])) {
      cancel()
      die()
    }
    @message = substr(@event['message'], length(@p) + 2)
    tmsg(@player, color(7).'(From '.player().'): '.color(r).colorize(@message))
    play_sound(ploc(@player), array('sound': 'CHICKEN_EGG_POP', 'pitch': 2), @player)
    msg(color(7).'(To '.@player.'): '.color(r).colorize(@message))
    console(player().' @ '.@player.': '.@message, false)
    import(@conv)
    @conv[@player] = player()
    @conv[player()] = @player
    export(@conv)
    cancel()
    die()
  }
  import(@ignorelist)
  if(array_index_exists(@ignorelist, player())) {
    @recipients = @event['recipients']
    for(@i = 0, @i < array_size(@ignorelist[player()]), @i++,
      if(@ignorelist[player()][@i] == 'all') {
        msg('You have been muted.')
        cancel()
        die()
      }
      for(@j = 0, @j < array_size(@recipients), @j++,
        if(@recipients[@j] == @ignorelist[player()][@i]) {
          array_remove(@recipients, @j)
        }
      )
    )
   modify_event('recipients', @recipients)
  }
  modify_event('message', colorize(@event['message']))
  modify_event('format', color('dark_gray').simple_date('h:mm').' '.if(array_contains(pgroup(), 'donors'), color('green').'\u2666 ')._colorname(player()).player().color('gray').': '.color('r').'%2$s')
)

# Block wither
bind('player_interact', array('priority': 'high'), array('item': 397), @event,
  if(pinv(player(), null)['data'] == '1' && !array_contains(array('custom', 'dev', 'outworld_nether', 'outworld', 'outworld_the_end'), pworld())) {
    cancel()
    msg(color('yellow').'Wither heads are currently restricted from being placed in this world.')
  }
)

# Infinite Cauldrons
bind('player_interact', null, array('block': 118, 'button': 'right'), @event,
  if(equals(@event['block'], '118:3'),
    switch(@event['item'],
      '325:0',
        @bucket = pinv(player(), null)
        if(@bucket['qty'] == 1) {
          set_pinv(array(null: array('type': 326, 'qty': 1)))
        } else {
          array_set(@bucket, 'qty', @bucket['qty'] - 1)
          set_pinv(array(null: @bucket))
          pgive_item(326, 1)
        },
      '374:0',
        set_timeout(100, closure(assign(@location, @event['location']), set_block_at(@location, '118:3')))
    )
  )
)

# Block lighters
bind('player_interact', null, array('item': 259, 'button': 'right'), @event,
  if(has_permission('group.regulars'), die())
  try(@loc = @event['location'], die())
  if(get_block_at(@loc) == '46:0') {
    die()
  } else if(get_block_at(@loc) == '49:0' && @event['facing'] == 'up') {
    set_timeout(50, closure(
      if(reg_split('\\:', get_block_at(@loc[0], @event['location'][1] + 1, @loc[2]))[0] != '90') {
        set_block_at(@loc[0], @loc[1] + 1, @loc[2], 0)
      }
    ))
  } else {
    cancel()
    msg('Flint and steel is restricted, but you can still use it on TNT and nether portals.')
  }
)

# Block fire charges
bind('player_interact', null, array('item': 385, 'button': 'right'), @event,
  if(has_permission('group.regulars'), die())
  cancel()
  msg('Flint and steel is restricted, but you can still use it on TNT and nether portals.')
)

# Button commands
bind('player_interact', null, array('block': 77, 'button': 'right'), @event,
  if(@event['location'][0] == '117' && @event['location'][1] == '64' && @event['location'][2] == '348' && @event['location'][3] == 'world3') {
    set_timeout(2300, closure(
      run('/dial supergate outworld galaxy')
    ))
    die()
  }
  @sign = _relative(@event['location'], 'up')
  if(is_sign_at(@sign)) { 
    @signtext = get_sign_text(@sign)
    if(@type = reg_match('\u00A7[0-9a-f]{1}\\[(.+)\\]', @signtext[1])) {
      switch(@type[1],
        'STOPWATCH',
          switch(@signtext[2],
            'Start',
              import(@stopwatch)
              if(!@stopwatch, @stopwatch = associative_array())
              @stopwatch[player()] = time()
              export(@stopwatch)
              msg(color(a), '[STOPWATCH] ', color('white'), 'GO!'),
            'Stop',
              import(@stopwatch)
              if(!array_index_exists(@stopwatch, player()), die('Did you start the stopwatch?'))
              @time = round(divide(subtract(time(), @stopwatch[player()]), 1000), 1)
              msg(color(a), '[STOPWATCH] ', color('white'), 'Time: ', @time, ' seconds.')
              console(player().' got a time of '.@time.' at '.sk_current_regions()),
              array_remove(@stopwatch, player())
              export(@stopwatch)
            die('Unknown StopWatch command.')
          ),
        'CONNECT4',
          switch(@signtext[2],
            'Reset',
              proc(_set_sand, @x, @y, @z,
                if(get_block_at(@x, @y, @z, pworld()) == '0:0', set_block_at(@x, @y, @z, 12, pworld()))
              )
              proc(_set_gravel, @x, @y, @z,
                if(get_block_at(@x, @y, @z, pworld()) == '0:0', set_block_at(@x, @y, @z, 13, pworld()))
              )
              _iterate_cuboid(array(-499, 73, -348), array(-499, 78, -342), '_set_sand')
              _iterate_cuboid(array(-499, 81, -348), array(-499, 86, -342), '_set_gravel'),
            die('Unknown Connect4 command.')
          ),
        'SNOWSPLEEF',
          switch(@signtext[2],
            'Reset Floor',
              proc(_set_snowblock, @x, @y, @z,
                if(get_block_at(@x, @y, @z, pworld()) == '0:0', set_block_at(@x, @y, @z, 80, pworld()))
              )
              _iterate_cuboid(array(-667, 63, -260), array(-644, 63, -283), '_set_snowblock')
              msg('Reset.'),
            die('Unknown SnowSpleef command.')
          ),
        if(is_alias('/'.to_lower(@type[1]).if(@signtext[2] != '', ' '.to_lower(@signtext[2])).if(@signtext[3] != '', ' '.to_lower(@signtext[3])))) {
          call_alias('/'.to_lower(@type[1]).' '.to_lower(@signtext[2]).' '.to_lower(@signtext[3]))
        } else {
          die('Unknown button command.')
        }
      )
    } else if(length(@signtext[1]) > 1 && @signtext[1][0] == '/' && length(@signtext[0]) > 2 && substr(@signtext[0], 0, 2) == color(1)) {
      msg('Ran command:' @signtext[1] @signtext[2] @signtext[3])
      if(!call_alias(@signtext[1] @signtext[2] @signtext[3]), run(@signtext[1] @signtext[2] @signtext[3]))
    }
  }
)

# automatically color command signs placed above buttons
bind('sign_changed', null, null, @event,
  if(has_permission('group.moderators') 
    && split(':', get_block_at(@event['location'][0], @event['location'][1] - 1, @event['location'][2], @event['location'][3]))[0] == '77') {
    if(@event['text'][2] != ''
      && reg_count('^\\[\\w+\\]$', @event['text'][1]) == 1) {
      modify_event('2', color(2).@event['text'][1])
    } else if(length(@event['text'][1]) > 0 && @event['text'][1][0] == '/' && @event['text'][0] != '') {
      modify_event('1', color(1).@event['text'][0])
    }
  }
)

# COIN SHOPS!
bind('player_interact', null, array('block': 68), @event,
@signtext = get_sign_text(@event['location'])
if(length(@signtext[3]) > 8 && substr(@signtext[3], 0, 3) == color('yellow').'-') { #Coin reward signs
  @cost = reg_match('.*\\-(\\d{1,3})\\sCoins', @signtext[3])
  @chestloc = array(@event['location'][0], @event['location'][1] - 1, @event['location'][2], @event['location'][3])
  @count = _get_inventory_count(@chestloc, 'all')
  if(@event['action'] == 'left_click_block') {
    msg(color('yellow').'[Coin Shop] '.color(r).@count.' item(s) left. Your coins: '.if(acc_balance(player()) < @cost[1], color('red'), color('green')).round(acc_balance(player())))
  } else { #right_click_block
    if(array_contains_ic(array('JewManGroup'), player())) { 
      die('You are not allowed to use coins due to cheating.')
    }
    if(@count < 1, die(color('yellow').'[Coin Shop] '.color(r).'There are no items left.'))
    if(acc_balance(player()) < @cost[1], die(color('yellow').'[Coin Shop] '.color(r).'You only have '.color('red').round(acc_balance(player())).color(r).' left.'))
    for(@i = 0, @i < get_inventory_size(@chestloc), @i++,
      if(get_inventory_item(@chestloc, @i) != null) {
        if(_pgive_item(player(), get_inventory_item(@chestloc, @i)) == true) {
          set_inventory_item(@chestloc, @i, null)
          acc_subtract(player(), @cost[1])
          msg(color('yellow').'[Coin Shop] '.color(r).'Transaction successful. Your coins: '.round(acc_balance(player())).' (-'.@cost[1].')')
          break()
        } else {
          msg(color('yellow').'[Coin Shop] '.color(r).'You have no room in your inventory.')
        }
      }
    )
  }
}
)

# Sponge splitting
bind('block_break', null, array('type': 19), @event,
  if(rand(16) < 1, drop_item(@event['location'], array('type': 19)))
)

#disable hopper minecarts
bind('player_interact', null, array('item': 408), @event,
if(pworld() != 'custom' && pworld() != 'dev') {
  msg(color('red').'Hopper minecarts are currently disabled.')
  cancel()
}
)

bind('inventory_click', null, array('slottype': 'RESULT', 'slotitem': 408), @event,
  msg(color('red').'Hopper minecarts are currently disabled.')
  cancel()
)

#disable flint & steel and fire charges in dispensers for non-regulars
bind('inventory_click', null, array('slottype': 'CONTAINER'), @event,
  if(@event['inventorytype'] == 'DISPENSER' 
  && !has_permission('group.regulars')
  && ((@event['cursoritem'] != null && (@event['cursoritem']['type'] == 259 || @event['cursoritem']['type'] == 385) && @event['rawslot'] < 9)
  || (@event['slotitem'] != null && (@event['slotitem']['type'] == 259 || @event['slotitem']['type'] == 385) && @event['shiftclick']))) {
    cancel()
    die(color('red').'You cannot place flint & steel or firecharges in dispensers.')
  }
)

bind('player_interact', null, array('block': 122), @e,
  if(pmode() != 'CREATIVE' && (pworld() == 'custom' || pworld() == 'dev'), cancel())
)

bind('entity_explode', null, null, @e,
  if(@e['location'][3] == 'custom' && @e['type'] != 'PRIMED_TNT', cancel())
)

# DISPENER PARKING
bind('vehicle_collide', null, array('type': 'MINECART', 'collisiontype': 'BLOCK', 'hittype': 23), @e,
  for(@i = 0, @i < get_inventory_size(@e['block']), @i++,
    if(is_null(get_inventory_item(@e['block'], @i))) {
      set_inventory_item(@e['block'], @i, array('type': 328, 'qty': 1))
      entity_remove(@e['id'])
      break()
    }
  )
)

