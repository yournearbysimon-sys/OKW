-- NOTE: This files is not loaded in the runtime.
-- Which means, its only to demonstrate examples of those events, not actually implementing your code in here.
-- If you want to use any event here, just copy it and paste in your own script.

AddEventHandler("prism_uipack:contextOpened", function()
    print("Context menu opened")
end)

AddEventHandler("prism_uipack:contextClosed", function()
    print("Context menu closed")
end)