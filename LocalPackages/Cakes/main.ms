# Clicking cakes
bind(player_interact, null, array('block': 92), @event,
  if(pworld() != 'custom', die())
  @cakes = get_value('cakes')
  @id = array_index(@cakes, @event['location'])
  if(!@id, die())
  cancel()
  @cakedata = get_value('cakeinfo.'.@id)
  if(!@cakedata, die('The cake is a lie.'))
  if(@cakedata['type'] == 'challenge') {
    foreach(@cakedata['players'], @player, @time,
      if((@time + (90 * 86400000)) < time()) {
        array_remove(@cakedata['players'], @player)
      }
    )
    if(array_index_exists(@cakedata['players'], player())) {
      @daysleft = round(((@cakedata['players'][player()] + (90 * 86400000)) - time()) / 86400000)
      if(get_block_at(@event['location']) != '92:0', set_block_at(@event['location'], '92:0'))
      if(@daysleft == 0, die('Less than a day left on your cooldown for this cake.'))
      die(@daysleft.' days left on your cooldown for this cake')
    }
  } else if(@cakedata['type'] == 'secret') {
    if(array_index_exists(@cakedata['players'], player())) {
      die('You\'ve already found this cake.')
    }
  }
  @allcakes = get_values('cakeinfo')
  @count = 1
  @total = 0
  foreach(@allcakes, @cake,
    if(@cake['type'] == @cakedata['type']) {
      @total = @total + 1
      if(array_index_exists(@cake['players'], player())) {
        @count = @count + 1
      }
    }
  )
  @cakedata['players'][player()] = time()
  msg(color('green').'You got the '.to_upper(@id).' '.@cakedata['type'].' cake! ('.@count.'/'.@total.')')
  if(!array_contains_ic(pgroup(), 'builders')) {
    acc_add(player(), @cakedata['coins'])
    msg(color('gold').'+ '.@cakedata['coins'].' coins')
    console(player().' got '.@cakedata['coins'].' coins at '.@id)
  }
  store_value('cakeinfo.'.@id, @cakedata)
  make_effect(@event['location'], 'ENDER_SIGNAL')
  make_effect(@event['location'], 'RECORD_PLAY:2263')
  if(get_block_at(@event['location']) != '92:0', set_block_at(@event['location'], '92:0'))
)