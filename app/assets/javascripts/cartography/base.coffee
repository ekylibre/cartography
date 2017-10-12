((C, $) ->
  "use strict"

  class C.BaseClass
    constructor: (map) ->
      @map = map

    getMap: ->
      @map

)(window.Cartography = window.Cartography || {}, jQuery)
