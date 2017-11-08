((C) ->
  "use strict"

  C.Events = {}
  C.Events.new = {}
  C.Events.new.start = "cartography:events:new:start"
  C.Events.new.complete = "cartography:events:new:complete"
  C.Events.new.cancel = "cartography:events:new:cancel"
  C.Events.new.change = "cartography:events:new:change"

)(window.Cartography = window.Cartography || {})
