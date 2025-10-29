luaBukkit.env:listenerBuilder()
    :subscribe({
        event = "PlayerJoinEvent",
        priority = "LOW",
        handler = function(event)
            event:getPlayer():sendMessage("Hi " .. event:getPlayer():getName())
        end
    })
    :build()
    :register("SayHello.GreetingEvent")