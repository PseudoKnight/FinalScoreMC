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