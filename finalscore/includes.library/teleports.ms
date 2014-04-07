@blockedworlds = array('outworld', 'outworld_nether', 'outworld_the_end')

#Warms up a tp with effects and configurable timer
proc(_warmuptp, @length, @player, @loc, @yaw = null, @pitch = null,
  set_peffect(@player, 9, 1, 7)
  play_sound(ploc(@player), array('sound': 'PORTAL_TRIGGER', 'volume': 1, 'pitch': 1))
  set_timeout(round(@length * 1000), closure(
    if(!ponline(@player), die())
    play_sound(ploc(@player), array('sound': 'GHAST_FIREBALL', 'volume': 2))
    make_effect(ploc(@player), 'MOBSPAWNER_FLAMES', 20)
    if(!is_null(@yaw) && !is_null(@pitch)) {
      pfacing(@player, @yaw, @pitch)
    }
    set_ploc(@player, @loc)
    set_peffect(@player, 15, 1, 1)
    play_sound(ploc(@player), array('sound': 'GHAST_FIREBALL', 'volume': 2))
    make_effect(@loc, 'MOBSPAWNER_FLAMES', 20)
  ))
)