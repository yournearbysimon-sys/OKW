# Sandy Shores Motel

You can unload the rooms to use your own TP instance rooms. To do this, use the `cfx_gn_sandy_ipl_loader` script provided in the G&N's Sandy Remaster Bundle.  

For more information, check our documentation here: https://g-n-s-studio.github.io/docs/category/sandy-shores-remaster


### **Removing the Motel Room MLOs**  
**Solution ONLY if you don't have `cfx_gn_sandy_ipl_loader`** (If used without sandy's remaster))

1. **Delete** the **YMAP folder** in:  
   `cfx_gn_sandy_motel\stream\interior\ymap`  

2. **Add** the "blocker" folder to stream folder provided in the **[Additional Patch]**.  

➡️ If you own the **Sandy Shores Remaster**, you **don't need to do this**.  
Simply modify the line:   ["Sandy_Motel"] = true or false, in `cfx_gn_sandy_ipl_loader\config.lua`