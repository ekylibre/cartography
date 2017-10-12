#= require cartography/base
#= require cartography/controls
#= require cartography/layers
#= require cartography/layers/simple

((C, $) ->
  "use strict"

  class C.Map extends C.BaseClass
    options:
      box:
        height: '400px'
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
      snap: true

    constructor: (id, options = {}) ->
      L.Util.setOptions @, options

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
      @getMap().on "draw:created", (e) =>
        @controls.get('edit').addLayer(e.layer)
        @controls.get('edit').addTo(control) if control = @controls.get('overlays').getControl()

    controls: ->
      @controls = new C.Controls(@getMap(), @options)

      layerSelector = new C.Controls.Layers(undefined, @getMap(), @options)

      @controls.add 'layers', layerSelector

      @controls.add 'backgrounds', new C.Controls.BaseLayers(layerSelector.getControl(), @getMap(), @options), false
      @controls.add 'overlays', new C.Controls.OverlayLayers(layerSelector.getControl(), @getMap(), @options), false

      editControl = new C.Controls.Edit(@getMap(), @options)
      @controls.add 'edit', editControl

      @controls.add 'scale', new C.Controls.Scale(@getMap(), @options)

      # Display selector if shapes are editable
      if @options.edit? and layerSelector?
        editControl.addTo layerSelector.getControl()

      if @options.snap?
        layers = @controls.get('overlays').getLayers()
        snappable_layers = []

        for k,v of layers
          snappable_layers.push v

        L.Util.setOptions @, {snap: {polygon: {guideLayers: snappable_layers}}}

        new C.Controls.Edit.Snap(@getMap(), editControl, @options)

    setView: ->
      @getMap().fitWorld({ maxZoom: 21 })

)(window.Cartography = window.Cartography || {}, jQuery)
