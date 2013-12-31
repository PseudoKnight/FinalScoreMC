#Warms up a tp with effects and configurable timer
proc(_warmuptp, @length, @player, @loc, assign(@yaw, ''), assign(@pitch, ''),
  set_peffect(@player, 9, 1, 7)
  play_sound(ploc(@player), array('sound': 'PORTAL_TRIGGER', 'volume': 1, 'pitch': 1))
  set_timeout(round(@length * 1000), closure(
    if(!ponline(@player), die())
    make_effect(ploc(@player), 'GHAST_SHOOT', 20)
    make_effect(ploc(@player), 'MOBSPAWNER_FLAMES', 20)
    if(@yaw != '' && @pitch != '') {
      pfacing(@player, @yaw, @pitch)
    }
    set_ploc(@player, @loc)
    set_peffect(@player, 15, 1, 1)
    make_effect(@loc, 'GHAST_SHOOT', 20)
    make_effect(@loc, 'MOBSPAWNER_FLAMES', 20)
  ))
)
