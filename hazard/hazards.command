register_command('hazard', array(
    'description': 'Creates, joins and starts a half-hazard game.',
    'usage': '/hazard <join|start>',
    'tabcompleter': closure(@alias, @sender, @args, @info) {
        if(array_size(@args) == 1) {
            return(_strings_start_with_ic(array('join', 'start'), @args[-1]));
        }
        return(array());
    },
    'executor': closure(@alias, @sender, @args, @info) {
        if(!@args) {
            return(false);
        }
        include('core.library/game.ms');
        include('core.library/player.ms');
        switch(@args[0]) {
            case 'join':
                @game = import('hazard');
                if(!@game) {
                    @game = _hazard_create();
                }
                _hazard_add_player(@sender, @game);
                broadcast(display_name(@sender).color('reset').' joined hazard.', all_players(@game['world']));

            case 'start':
                @game = import('hazard');
                if(!@game || array_size(@game['players']) < 1) {
                    die(color('gold').'Not enough players!');
                }
                if(@game['running']) {
                    die(color('gold').'Already running!');
                }
                msg('Preparing hazard map...');
                _hazard_start(@game);

            case 'reload':
                if(player() != '~console' && !pisop()) {
                    die(color('red').'No permission.');
                }
                x_recompile_includes('core.library');
                msg(color('green').'Done!');

            default:
                return(false);
        }
    },
));
