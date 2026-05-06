# Motel Room Instance Script

## 🏠 How to disable furniture

To configure furniture for each room, open the file **`mh_room_main.lua`** and set `furnished = true` or `furnished = false` for each configuration:

```lua
furnished = false, -- Empty room (without furniture)
```

or

```lua
furnished = true, -- Room with furniture
```

### Example

In `mh_room_main.lua`, for each room configuration:

```lua
local interiors = {
    {
        ipl = 'instance_int_gn_motel_room_01l_milo_',
        coords = vec3(-1179.14221, 1117.6582, 0.626481533),
        furnished = false, -- Change here: true = with furniture | false = without furniture
        entitySets = { ... },
        doors = { ... }
    }
}
```

**That's it!** The script automatically handles furniture activation/deactivation.
