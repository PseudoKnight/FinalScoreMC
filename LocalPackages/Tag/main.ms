bind('entity_damage_player', null, null, @e,
  if(@e['damager'] == 'PLAYER' && @e['cause'] == 'ENTITY_ATTACK') {
    @it = get_value('it')
    if(@e['data'] == @it['player']) {
      store_value('it', array('player': @e['player'], 'time': time()))
      tmsg(@e['player'], color('green').@e['data'].' tagged you. You are "IT"!')
      tmsg(@e['data'], color('green').'You tagged '.@e['player'].'. They are "IT"!')
      cancel()
    }
  }
)