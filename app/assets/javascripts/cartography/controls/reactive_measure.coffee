((C, $) ->
  "use strict"

  class C.Controls.ReactiveMeasure extends C.Controls

    options:
      reactiveMeasure:
        position: 'bottomright'
        metric: true
        feet: false
        tooltip: false

    constructor: (map, layer, options = {}) ->
      super(map)
      C.Util.setOptions @, options
      @layer = layer
      @control = new L.ReactiveMeasureControl(layer, @options.reactiveMeasure)
    
      @initHooks()
    
    initHooks: ->
      @map.on L.Draw.Event.CREATED,  (e) =>
        @control.updateContent(@layer.getMeasure())
      , @

      @map.on 'draw:edited',  (e) =>
        @control.updateContent(@layer.getMeasure())
      , @
      
      @map.on 'draw:deleted',  (e) =>
        @control.updateContent(@layer.getMeasure())
      , @

      @layer.on 'layeradd', (e) =>
        @control.updateContent(@layer.getMeasure())
      , @
      
    

    getControl: ->
      @control
    
  
)(window.Cartography = window.Cartography || {}, jQuery)