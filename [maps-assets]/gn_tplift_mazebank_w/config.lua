ELEVATOR_MENU_TITLE = "Elevator"
ELEVATOR_MENU_DESCRIPTION = "The world fastest elevator!"
MARKER_NOTIFICATION = "Press ~INPUT_CONTEXT~ to access ~b~elevator menu"

ZONES = {
    --Mazebank West--
    ['mazebank_west_a'] = {
        label = 'Main floor',
        coords = vec4(-1357.7070, -479.6301, 33.1756, 100.0432),
        interactDistance = 1.5,
        renderDistance = 5.0,
        directions = {
            'mazebank_west_upper'
        }
    },
    ['mazebank_west_b'] = {
        label = 'Main floor',
        coords = vec4(-1358.2584, -476.3072, 33.1756, 100.0881),
        interactDistance = 1.5,
        renderDistance = 5.0,
        directions = {
            'mazebank_west_upper'
        }
    },
    ['mazebank_west_c'] = {
        label = 'Main floor',
        coords = vec4(-1364.4792, -477.2020, 33.1756, 274.9265),
        interactDistance = 1.5,
        renderDistance = 5.0,
        directions = {
            'mazebank_west_upper'
        }
    },
    ['mazebank_west_d'] = {
        label = 'Main floor',
        coords = vec4(-1364.0862, -480.6771, 33.1756, 279.1163),
        interactDistance = 1.5,
        renderDistance = 5.0,
        directions = {
            'mazebank_west_upper'
        }
    },
    ['mazebank_west_upper'] = {
        label = 'Boss office',
        coords = vec4(-1391.2173, -479.2841, 72.0421, 271.7285),
        interactDistance = 1.5,
        renderDistance = 5.0,
        directions = {
            'mazebank_west_a'
        }
    }
}