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
  C.Events.edit = {}
  C.Events.edit.start = "cartography:events:edit:start"
  C.Events.edit.complete = "cartography:events:edit:complete"
  C.Events.edit.cancel = "cartography:events:edit:cancel"
  C.Events.edit.change = "cartography:events:edit:change"

)(window.Cartography = window.Cartography || {})
