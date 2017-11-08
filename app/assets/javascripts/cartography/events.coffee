((C) ->
  "use strict"

  C.Events = {}
  C.Events.new = {}
  C.Events.new.start = "cartography:events:new:start"
  C.Events.new.complete = "cartography:events:new:complete"
  C.Events.new.cancel = "cartography:events:new:cancel"
  C.Events.new.change = "cartography:events:new:change"
  C.Events.split = {}
  C.Events.split.start = "cartography:events:split:start"
  C.Events.split.complete = "cartography:events:split:complete"
  C.Events.split.cancel = "cartography:events:split:cancel"
  C.Events.split.change = "cartography:events:split:change"
  C.Events.split.select = "cartography:events:split:select"

)(window.Cartography = window.Cartography || {})
