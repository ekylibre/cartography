((C) ->
  "use strict"

  C.Events = {}
  C.Events.new = {}
  C.Events.new.start = "cartography:events:new:start"
  C.Events.new.complete = "cartography:events:new:complete"
  C.Events.new.cancel = "cartography:events:new:cancel"
  C.Events.new.change = "cartography:events:new:change"
  C.Events.shapeDraw = {}
  C.Events.shapeDraw.start = "cartography:events:shapeDraw:start"
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
  C.Events.select = {}
  C.Events.select.select = "cartography:events:select:select"
  C.Events.select.unselect = "cartography:events:select:unselect"
  C.Events.select.selected = "cartography:events:select:selected"
  C.Events.select.start = "cartography:events:select:start"
  C.Events.select.stop = "cartography:events:select:stop"


)(window.Cartography = window.Cartography || {})
