local addonName, addonPrivate = ...
setfenv(1, addonPrivate)

Events ={}

function Events:new()
	local instance = {}
	setmetatable(instance, self)
	self.__index = self;
	instance.events = {}
	instance.eventFrame = CreateFrame("Frame")
	instance.eventFrame:SetScript("OnEvent", function(frame, event, ...)
	    local handler = instance.events[event]
	    local handler_t = type(handler)
	    if handler_t == "function" then
	        handler(event, ...)
	    elseif handler_t == "string" and A[handler] then
	        A[handler](event, ...)
	    end
	end)
	return instance
end

function Events:Register(event, handler)
    assert(self.events[event] == nil, "Attempt to re-register message: " .. tostring(event))
    self.events[event] = handler or event
    self.eventFrame:RegisterEvent(event)
end

function Events:Unregister(event)
    assert(type(event) == "string", "Invalid argument to 'Unregister'")
    self.events[event] = nil
    self.eventFrame:UnregisterEvent(event)
end


