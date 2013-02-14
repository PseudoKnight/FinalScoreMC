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

bind(player_login, null, null, @event,
  if(get_server_info(10)) {
    if(@event['result'] != 'ALLOWED', die())
    store_value('player.'.@event['player'].'.lastip', @event['ip'])
    @lastip = @event['ip']
  } else {
    @lastip = get_value('player.'.@event['player'].'.lastip')
  }
  if(@lastip != @event['ip']) {
    console(@event['player'].': '.@event['ip'].', '.@lastip)
    modify_event('result', 'KICK_OTHER')
    modify_event('kickmsg', 'Minecraft auth servers are down and your IP doesn\'t match our records.')
  }
)

# Player join messages and tab list colors
bind(player_join, null, null, @event,
set_timeout(200, closure(assign(@loc, ploc()),
  #anti-cheat codes
  if(player() != 'PseudoKnight', msg('\u00A7f \u00A7f \u00A71 \u00A70 \u00A72 \u00A74 \u00A7f \u00A7f \u00A72 \u00A70 \u00A74 \u00A78 \u00A73 \u00A79 \u00A72 \u00A70 \u00A70 \u00A70 \u00A70\u00A70\u00A71\u00A72\u00A73\u00A74\u00A75\u00A76\u00A77\u00A78\u00A7f\u00A7e'))
  #Welcome messages
  msg(color('gold'), color(l), '\u2302', color('red'), color('l'), '\u2302', color('aqua'), color(l), '\u2302', color('dark_red'), color('l'), '\u2302', color('gold'), color('l'), ' FINALSCORE ', color('yellow'), color('l'), '\u00AB', color(r), ' \u25AA \u25AA \u25AA')
  msg(get_value('motd'))
  #Tab list colors
  if(length(player()) > 14) {
    set_list_name(_colorname().substr(player(), 0, 14))
  } else {
    set_list_name(_colorname().player())
  }
  set_timeout(1000, closure(
    if(@loc[1] > ploc()[1]) {
      set_ploc(@loc)
    }
  ))
))
)

# Teleport protection from falling through blocks
bind(player_teleport, null, null, @event,
  if(@event['to']['3'] != @event['from']['3']
  || _horizontal_distance(@event['to'], @event['from']) > 100) {
    set_timeout(350, closure(
      if((@event['to'][1] - 1) > ploc()[1])
      {
        set_ploc(array(@event['to'][0], @event['to'][1] - 1, @event['to'][2], @event['to'][3]))
        console('Adjusted position for '.player().' after teleport.')
      }
    ))
  }
)

# Tower Control respawn with gear
bind(player_spawn, null, null, @event,
  if(@event['location']['world'] == 'custom' && array_contains(sk_regions_at(@event['location']), 'irontower')) {
     set_pinv(@player, array(0: array(type: 272), 1: array(type: 261, enchants: array(array(etype: 'ARROW_INFINITE', elevel: 1))), 28: array(type: 262), 100: array(type: 305), 101: array(type: 300), 102: array(type: 303), 103: array(type: 306)))
  } else if(@event['location']['world'] == 'custom' && array_contains(sk_regions_at(@event['location']), 'goldtower')) {
    set_pinv(@player, array(0: array(type: 272), 1: array(type: 261, enchants: array(array(etype: 'ARROW_INFINITE', elevel: 1))), 28: array(type: 262), 100: array(type: 317), 101: array(type: 300), 102: array(type: 315), 103: array(type: 314)))
  }
)

# Handle all deaths
bind(player_death, null, null, @event,
# Log deaths and the drops
  if(!array_contains(array('custom', 'dev'), pworld())) {
    assign(@log, concat(@event['death_message'], ' at ', round(@event['location'][0]), ',', round(@event['location'][1]), ',', round(@event['location'][2]), ' on ', @event['location'][3], ', and dropped ', @event['xp'], 'xp and the following inventory:'))
    foreach(@event['drops'], @drop,
      if(is_array(@drop)) {
        assign(@log, sconcat(@log, if(@drop['qty'] > 1, @drop['qty']), data_name(@drop['type']), if(@drop['data'] > 0, sconcat('with', @drop['data'], 'damage')), if(gt(array_size(@drop['enchants']), 0), sconcat('with', @drop['enchants'], 'enchants')), '-'))
      }
    )
    console(@log, false)
  }
#Modify death_message
  if(pworld() == 'custom') {
    if(array_contains(sk_current_regions(), 'innerpitfrenzy1') || array_contains(sk_current_regions(), 'innerpitfrenzy2')) {
      _worldmsg('custom', concat(color(c), '[PITFRENZY] ', color('white'), @event['death_message']))
    } else if(array_contains(sk_current_regions(), 'towercontrol')) {
      _regionmsg('towercontrol', concat(color(a), '[TOWERCONTROL] ', color('white'), @event['death_message']))
      modify_event('drops', null)
    }
    modify_event('death_message', null)
  } 
# Notify player where he died.
  if(!array_contains(array('custom', 'dev'), pworld()), msg('You died @ ', round(@event['location'][0]), ',', round(@event['location'][1]), ',', round(@event['location'][2])))
)

# Outworld message
bind(world_changed, null, array('to': 'outworld'), @event,
  if(!array_contains(array('outworld_nether', 'outworld', 'outworld_the_end'), @event['from'])) {
    msg(color('k').'XX'.color('r').color('green').color('bold').' Welcome to the outworld! '.color('r').color('k').'XX')
    msg(color('gold').'This is a temporary world. Please do not build or store anything here you wish to keep.')
  }
)

# Log commands
bind(player_command, null, null, @event,
  if(is_alias(@event['command']) && !array_contains_ic(array('/join', '/accept', '/invite'), @event['prefix'])) {
    console(@event['player'].' ran: '.@event['command'], false)
  }
)

# PMs, ignores, and mutes
bind(player_chat, null, null, @event,
  if(@event['message'] == '-') {
    cancel()
    die()
  }
  if(substr(@event['message'], 0, 1) == '@') {
    try(assign(@player, player(substr(parse_args(@event['message'])[0], 1))), @ex,
      cancel()
      die('Player not found.')
    )
    assign(@message, substr(@event['message'], length(parse_args(@event['message'])[0]) + 1))
    tmsg(@player, color(7).'(From '.player().'): '.color(r).@message)
    msg(color(7).'(To '.@player.'): '.color(r).@message)
    console(player().' @ '.@player.': '.@message, false)
    import(@conv)
    array_set(@conv, @player, player())
    array_set(@conv, player(), @player)
    export(@conv)
    cancel()
    die()
  }
  import(@ignorelist)
  if(array_index_exists(@ignorelist, player())) {
    assign(@recipients, @event['recipients'])
    for(assign(@i, 0), @i < array_size(@ignorelist[player()]), @i++,
      if(@ignorelist[player()][@i] == 'all') {
        msg('You have been muted.')
        cancel()
        die()
      }
      for(assign(@j, 0), @j < array_size(@recipients), @j++,
        if(@recipients[@j] == @ignorelist[player()][@i]) {
          array_remove(@recipients, @j)
        }
      )
    )
   modify_event('recipients', @recipients)
  }
  modify_event('message', colorize(@event['message']))
  modify_event('format', color('dark_gray').simple_date('h:mm').' '._colorname(player()).player().color('gray').': '.color('r').'%2$s')
)

# Block wither
bind(player_interact, null, array('item': 397), @event,
  if(!has_permission('group.moderators') && pinv(player(), null)['data'] == '1' && !array_contains(array('custom', 'dev', 'outworld_nether', 'outworld', 'outworld_the_end'), pworld())) {
    cancel()
    msg(color('yellow').'Wither heads are currently restricted from being placed in this world.')
  }
)

# Infinite Cauldrons
bind(player_interact, null, array('block': 118, 'button': 'right'), @event,
  if(equals(@event['block'], '118:3'),
    switch(@event['item'],
      '325:0',
        assign(@bucket, pinv(player(), null))
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
bind(player_interact, null, array('item': 259, 'button': 'right'), @event,
  if(has_permission('group.regulars'), die())
  try(assign(@loc, @event['location']), die())
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
    msg('Flint and steel is restricted, but you can still use it on TNT.')
  }
)

# Snow layers
bind(player_interact, null, array('item': 78, 'button': 'right', 'block': 78), @event,
  cancel()
  if(get_block_at(@event['location']) == '78:7', die())
  if(_can_build(@event['location']) == false, die())
  assign(@data, '78:'.(split(':', get_block_at(@event['location']))[1] + 1))
  set_block_at(@event['location'], @data)
  @slot = pinv(player(), null)
  array_set(@slot, 'qty', @slot['qty'] - 1)
  set_pinv(array(null: @slot))
)

# Clicking cakes
bind(player_interact, null, array('block': 92), @event,
  if(pworld() != 'custom', die())
  @cakes = get_value('cakes')
  @id = array_index(@cakes, @event['location'])
  if(!@id, die())
  cancel()
  @cakedata = get_value('cakes.'.@id)
  if(!@cakedata, die('The cake is a lie.'))
  foreach(@cakedata['players'], @player, @time,
    if((@time + (@cakedata['cooldown'] * 86400000)) < time()) {
      array_remove(@cakedata['players'], @player)
    }
  )
  if(array_index_exists(@cakedata['players'], player())) {
    @daysleft = round(((@cakedata['players'][player()] + (@cakedata['cooldown'] * 86400000)) - time()) / 86400000)
    if(get_block_at(@event['location']) != '92:0', set_block_at(@event['location'], '92:0'))
    if(@daysleft == 0, die('Less than a day left on your cooldown for this cake.'))
    die(@daysleft.' days left on your cooldown for this cake')
  }
  if(!array_contains_ic(pgroup(), 'builders')) {
    @cakedata['players'][player()] = time()
    acc_add(player(), @cakedata['coins'])
    msg(color('gold').'+ '.@cakedata['coins'].' coins')
    console(player().' got '.@cakedata['coins'].' coins at '.@id)
    store_value('cakes.'.@id, @cakedata)
  } else {
    msg(color('gold').'Coins are for non-builders, but here.. enjoy some music!')
  }
  make_effect(@event['location'], 'ENDER_SIGNAL')
  make_effect(@event['location'], 'RECORD_PLAY:2263')
  if(get_block_at(@event['location']) != '92:0', set_block_at(@event['location'], '92:0'))
)

# Button commands
bind(player_interact, null, array('block': 77, 'button': 'right'), @event,
  if(@event['location'][0] == '117' && @event['location'][1] == '64' && @event['location'][2] == '348' && @event['location'][3] == 'world3') {
    set_timeout(2300, closure(
      run('/dial supergate outworld galaxy')
    ))
    die()
  }
  assign(@sign, array(@event['location'][0], add(@event['location'][1], 1), @event['location'][2]))
  if(is_sign_at(@sign)) { 
    assign(@signtext, get_sign_text(@sign))
    if(length(@signtext[1]) > 6 && substr(@signtext[1], 0, 3) == concat(color(2), '[')) {
      switch(strip_colors(@signtext[1]),
        '[SPLEEF]',
          switch(@signtext[2], 
            'Join',
              call_alias('/spleef join'),
            'Start',
              call_alias('/spleef start'),
            die('Unknown Spleef command.')
          ),
        '[STOPWATCH]',
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
        '[SKYPIRATES]',
          switch(@signtext[2],
            'Join',
              call_alias('/skypirates join'),
            die('Unknown Skypirates command.')
          ),
        '[CONNECT4]',
          switch(@signtext[2],
            'Reset',
              proc(_set_sand, @x, @y, @z,
                if(get_block_at(@x, @y, @z, pworld()) == '0:0', set_block_at(@x, @y, @z, 12, pworld()))
              )
              proc(_set_gravel, @x, @y, @z,
                if(get_block_at(@x, @y, @z, pworld()) == '0:0', set_block_at(@x, @y, @z, 13, pworld()))
              )
              proc(_set_air, @x, @y, @z,
                if(get_block_at(@x, @y, @z, pworld()) != '0:0', set_block_at(@x, @y, @z, 0, pworld()))
              )
              _iterate_cuboid(array(-499, 73, -348), array(-499, 78, -342), '_set_sand')
              _iterate_cuboid(array(-499, 81, -348), array(-499, 86, -342), '_set_gravel')
              _iterate_cuboid(array(-500, 72, -342), array(-500, 66, -348), '_set_air')
              msg(color(a), '[CONNECT4] ', color('white'), 'Reset.'),
            die('Unknown Connect4 command.')
          ),
        '[CLUCK]',
          switch(@signtext[2],
            'Start',
              call_alias('/cluck start '.(@signtext[3] - 1)),
            die('Unknown Cluck command.')
          ),
        '[SNOWSPLEEF]',
          switch(@signtext[2],
            'Reset Floor',
              proc(_set_snowblock, @x, @y, @z,
                if(get_block_at(@x, @y, @z, pworld()) == '0:0', set_block_at(@x, @y, @z, 80, pworld()))
              )
              _iterate_cuboid(array(-667, 63, -260), array(-644, 63, -283), '_set_snowblock')
              msg('Reset.'),
            die('Unknown SnowSpleef command.')
          ),
        '[PVP]',
          switch(@signtext[2],
            'Join',
              call_alias('/pvp join '.to_lower(@signtext[3])),
            'Start',
              call_alias('/pvp start '.to_lower(@signtext[3])),
            die('Unknown PVP command.')
          ),
        die('Unknown button command.')
      )
    } else if(length(@signtext[1]) > 1 && @signtext[1][0] == '/' && length(@signtext[0]) > 2 && substr(@signtext[0], 0, 2) == color(1)) {
      msg('Ran command:' @signtext[1] @signtext[2] @signtext[3])
      if(!call_alias(@signtext[1] @signtext[2] @signtext[3]), run(@signtext[1] @signtext[2] @signtext[3]))
    }
  }
)

bind(sign_changed, null, null, @event,
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

# CLICKING SIGNS!
bind(player_interact, null, array('block': 68), @event,
assign(@signtext, get_sign_text(@event['location']))
ifelse(length(@signtext[0]) > 2 && @signtext[0][0] == '['
&& (length(@signtext[1]) > 7 && substr(@signtext[1], 0, 3) == 'Buy'
|| length(@signtext[2]) > 8 && substr(@signtext[2], 0, 4) == 'Sell'),
  set_timeout(100, closure(
  assign(@itemid, _shop_item(@signtext[0]))
  assign(@shops, get_value('shops.'.@itemid))
  if(@shops == null, @shops = array(array(), array()))
  if(length(@signtext[1]) > 7 && substr(@signtext[1], 0, 3) == 'Buy') {
    assign(@count, _get_inventory_count(array(@event['location'][0], @event['location'][1] - 1, @event['location'][2], @event['location'][3]), reg_replace('\\.', ':', @itemid)))
    # debug #
    if(!is_array(@shops[0]), console('This shop list is not an array: '.@shops))
    foreachelse(array_keys(@shops[0]), @i,
      if(@shops[0][@i]['location'] == @event['location']) {
        if(@count < parse_args(@signtext[1])[1]) {
          array_remove(@shops[0], @i)
        } else {
          array_set(@shops[0], @i, array('location': @event['location'], 'price': substr(@signtext[1], 4), 'owner': @signtext[3], 'stock': @count))
        }
        break()
      }
      if(@i == (length(@shops[0]) - 1)) {
        if(@count >= parse_args(@signtext[1])[1]) {
          array_push(@shops[0], array('location': @event['location'], 'price': substr(@signtext[1], 4), 'owner': @signtext[3], 'stock': @count))
        }
      }
    , #else
      if(@count >= parse_args(@signtext[1])[1]) {
        @shops[0] = array(array('location': @event['location'], 'price': substr(@signtext[1], 4), 'owner': @signtext[3], 'stock': @count))
      }
    )
  }

  if(length(@signtext[2]) > 8 && substr(@signtext[2], 0, 4) == 'Sell') {
    switch(substr(@signtext[2], length(@signtext[2]) - 1)
    , 'g',
      @currency = '266'
    , 'i',
      @currency = '265'
    , 'd',
      @currency = '264'
    , 'e',
      @currency = '388'
    , die()
    )
    assign(@count, _get_inventory_count(array(@event['location'][0], @event['location'][1] - 1, @event['location'][2], @event['location'][3]), @currency.':0'))
    @cost = parse_args(@signtext[2])[3]
    try(
    foreachelse(array_keys(@shops[1]), @i,
      if(@shops[1][@i]['location'] == @event['location']) {
        if(@count < substr(@cost, 0, length(@cost) - 1)) {
          array_remove(@shops[1], @i)
        } else {
          array_set(@shops[1], @i, array('location': @event['location'], 'price': substr(@signtext[2], 5), 'owner': @signtext[3], 'stock': @count))
        }
          break()
      }
      if(@i == (length(@shops[1]) - 1)) {
        if(@count >= substr(@cost, 0, length(@cost) - 1)) {
          array_push(@shops[1], array('location': @event['location'], 'price': substr(@signtext[2], 5), 'owner': @signtext[3], 'stock': @count))
        }
      }
    , #else
      if(@count >= substr(@cost, 0, length(@cost) - 1)) {
        @shops[1] = array(array('location': @event['location'], 'price': substr(@signtext[2], 5), 'owner': @signtext[3], 'stock': @count))
      }
    )
    , #catch
    console('Shop debug: '.@shops)
    )
  }

  if(@shops == array(array(), array())) {
    clear_value('shops.'.@itemid)
  } else {
    store_value('shops.'.@itemid, @shops)
  }

  ))
, #else if
length(@signtext[3]) > 8 && substr(@signtext[3], 0, 3) == color('yellow').'-', #Coin reward signs
  assign(@cost, reg_match('.*\\-(\\d{1,3})\\sCoins', @signtext[3]))
  assign(@chestloc, array(@event['location'][0], @event['location'][1] - 1, @event['location'][2], @event['location'][3]))
  assign(@count, _get_inventory_count(@chestloc, 'all'))
  if(@event['action'] == 'left_click_block') {
    msg(color('yellow').'[Coin Shop] '.color(r).@count.' item(s) left. Your coins: '.if(acc_balance(player()) < @cost[1], color('red'), color('green')).round(acc_balance(player())))
  } else { #right_click_block
    if(array_contains_ic(array('JewManGroup'), player())) { 
      die('You are not allowed to use coins due to cheating.')
    }
    if(@count < 1, die(color('yellow').'[Coin Shop] '.color(r).'There are no items left.'))
    if(acc_balance(player()) < @cost[1], die(color('yellow').'[Coin Shop] '.color(r).'You only have '.color('red').round(acc_balance(player())).color(r).' left.'))
    for(assign(@i, 0), @i < get_inventory_size(@chestloc), @i++,
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
)
)

# Breaking signs
bind(block_break, null, array('type': 68), @event,
  assign(@location, array(@event['block']['X'], @event['block']['Y'], @event['block']['Z'], @event['block']['world']))
  assign(@signtext, get_sign_text(@location))
  if(length(@signtext[0]) < 3 || @signtext[0][0] != '[', die())
  if(!(length(@signtext[1]) > 7 && substr(@signtext[1], 0, 3) == 'Buy')
  && !(length(@signtext[2]) > 8 && substr(@signtext[2], 0, 4) == 'Sell'), die())
  assign(@itemid, _shop_item(@signtext[0]))
  assign(@shops, get_value('shops.'.@itemid))
  if(!@shops, die())
  if(length(@signtext[1]) > 7 && substr(@signtext[1], 0, 3) == 'Buy') {
    if(@shops[0] != array()) {
      for(assign(@i, 0), @i < length(@shops[0]), @i++,
        if(@shops[0][@i]['location'] == @location && (@shops[0][@i]['owner'] == player() || has_permission('group.moderators'))) {
          array_remove(@shops[0], @i)
          break()
        }
      )
    }
  }
  if(length(@signtext[2]) > 8 && substr(@signtext[2], 0, 4) == 'Sell') {
    if(@shops[1] != array()) {
      for(assign(@i, 0), @i < length(@shops[1]), @i++,
        if(@shops[1][@i]['location'] == @location && (@shops[1][@i]['owner'] == player() || has_permission('group.moderators'))) {
          array_remove(@shops[1], @i)
          break()
        }
      )
    }
  }
  if(@shops == array(array(), array())) {
    clear_value('shops.'.@itemid)
  } else {
    store_value('shops.'.@itemid, @shops)
  }
)


# Sponge splitting
bind(block_break, null, array('type': 19), @event,
  if(rand(16) < 1, item_drop(array(@event['block']['X'], @event['block']['Y'], @event['block']['Z'], @event['block']['world']), 19, 1))
)

