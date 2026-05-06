# Compatibility Notice – `vb_occl_01.ymap`

The resources `cfx_gn_vespucci_pd` and `cfx_gn_burgershot_vespucci` both modify the same in-game occlusion file: `vb_occl_01.ymap`.

If you are using **both resources**, please **delete the `vb_occl_01.ymap` files** already present in each of them  
(located in `stream/base` folders).

Then, add the **provided compatibility version** of the file included with this package.  
You can place it:

- either inside **one of the two resources**,  
- or in a **dedicated compatibility resource** such as `myserver_compatibility` (recommended if you manage multiple add-on conflicts).

This ensures proper occlusion handling and prevents resource conflicts.