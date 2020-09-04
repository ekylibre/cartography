((C, $) ->
  "use strict"

  class C.Controls.Importer extends C.Controls

    constructor: (map, options = {}) ->
      super(map)

      C.Util.setOptions @, options
      @control = new L.Control.Importer(map, @options.importer)

    getControl: ->
      @control
    
  
)(window.Cartography = window.Cartography || {}, jQuery)
