#= require cartography/util
#= require cartography/base
#= require cartography/controls
#= require cartography/layers
#= require cartography/layers/simple

((C, $) ->
  "use strict"

  class C.Map extends C.BaseClass
    options:
      box:
        height: '85vh'
        width: undefined
      map:
        scrollWheelZoom: true
        zoomControl: true
        attributionControl: true
        setDefaultBackground: false
        setDefaultOverlay: false
        dragging: true
        touchZoom: true
        doubleClickZoom: true
        boxZoom: true
        tap: true
      controls:
        edit: true
        snap: true
        reactiveMeasure: true
      snap:
        polygon:
          snapDistance: 15
          snapOriginDistance: 15

    constructor: (id, options = {}) ->
      C.Util.setOptions @, options

      @baseElement = L.DomUtil.get(id)
      @mapElement = L.DomUtil.create('div', 'map', @baseElement)

      @map = L.map(@mapElement, @options.map)

      @resize()

      @controls()

      @initHooks()

      @setView()

    resize: ->
      if @options.box? and @options.box.height?
        @mapElement.style.height = @options.box.height
      if @options.box? and @options.box.width?
        @mapElement.style.width = @options.box.width

    initHooks: ->

      @controls.get('draw').toolbar.on 'enable', (e) =>
        @getMap().on L.Draw.Event.CREATED, (e) =>
          @controls.get('edit').addLayer(e.layer)
          @controls.get('edit').addTo(control) if control = @controls.get('overlays').getControl()

      @controls.get('draw').toolbar.on 'disable', (e) =>
        @getMap().off L.Draw.Event.CREATED

      @getMap().on L.Selectable.Event.SELECT, (e) ->
        console.error 'select',e.layer

      @getMap().on L.Selectable.Event.UNSELECT, (e) ->
        console.error 'unselect', e.layer

      @getMap().on L.Selectable.Event.SELECTED, (e) ->
        console.error 'selected layers', e

      @getMap().on L.Selectable.Event.START, (e) ->
        console.error "Starting selection mode"

      @getMap().on L.Selectable.Event.STOP, (e) ->
        console.error "Stopping selection mode"

    controls: ->
      @controls = new C.Controls(@getMap(), @options)

      layerSelector = new C.Controls.Layers(undefined, @getMap(), @options)

      @controls.add 'layers', layerSelector

      @controls.add 'backgrounds', new C.Controls.BaseLayers(layerSelector.getControl(), @getMap(), @options), false
      @controls.add 'overlays', new C.Controls.OverlayLayers(layerSelector.getControl(), @getMap(), @options), false

      if @options.controls.snap?
        layers = @controls.get('overlays').getLayers()

        @options.snap.polygon.guideLayers = Object.values(layers)

      drawControl = new C.Controls.Draw(@getMap(), @options)
      @controls.add 'draw', drawControl

      # Display selector if shapes are editable
      # if @options.controls.edit? and layerSelector?
        # editControl.addTo layerSelector.getControl()

      @controls.add 'edit', new C.Controls.Edit(@getMap(), @options)
      @controls.add 'scale', new C.Controls.Scale(@getMap(), @options)

      if @options.controls.reactiveMeasure?
        @controls.add 'measure', new C.Controls.Edit.ReactiveMeasure(@getMap(), @controls.get('edit'), @options)


      #TODO:
      layers = L.featureGroup(Object.values(@controls.get('overlays').getLayers())[0].getLayers())
      C.Util.setOptions @, layerSelection: {featureGroup: layers}

      @controls.add 'selection', new C.Controls.LayerSelection(@getMap(), @options)

      C.Util.setOptions @, cut: {featureGroup: Object.values(@controls.get('overlays').getLayers())[0]}
      @controls.add 'cut', new C.Controls.Cut(@getMap(), @options)

    setView: ->
      #TMP
      layers = @controls.get('overlays').getLayers()
      bounds = []
      for k,v of layers
        bounds = v.getBounds()

      @getMap().fitBounds(bounds,{ maxZoom: 21 })

)(window.Cartography = window.Cartography || {}, jQuery)
