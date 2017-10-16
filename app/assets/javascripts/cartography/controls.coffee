((C, $) ->
  "use strict"

  class C.Control extends C.BaseClass
    constructor: (map) ->
      super(map)

  class C.Controls extends C.Control
    constructor: (map) ->
      @controls = {}

      super(map)

    add: (id, control, addToMap = true) ->
      @controls[id] = control
      @getMap().addControl control.getControl() unless !addToMap

    remove: (id, control) ->
      @controls[id] = undefined

    get: (id) ->
      @controls[id]

  class C.Controls.Layers extends C.Controls
    constructor: ( control, map, options = {} ) ->
      super(map)

      L.Util.setOptions @, options

      @control = control || new L.Control.Layers()

      @layers = {}

    getLayers: ->
      @references.getLayers()

    getLayer: (name) ->
      @references.getLayers()[name]

    getControl: ->
      @control

  class C.Controls.BaseLayers extends C.Controls.Layers
    options:
      backgrounds: [
        'OpenStreetMap.HOT',
        'OpenStreetMap.Mapnik',
        'Thunderforest.Landscape',
        'Esri.WorldImagery'
      ]

    constructor: ( control, map, options = {} )->
      L.Util.setOptions @, options
      super(control, map)

      @references = new C.BaseLayers(map, @options)
      @add(@options.backgrounds)

      @setActive(0)

    add: (layers) ->
      newLayers = @references.add(layers)

      for name, layer of newLayers
        @getControl().addBaseLayer(layer, name)

    setActive: (index) ->
      @getMap().addLayer(@getLayers()[Object.keys(@getLayers())[index]])

  class C.Controls.OverlayLayers extends C.Controls.Layers
    options:
      minZoom: 0
      maxZoom: 25
      overlays: []
      series: {}

    constructor: ( control, map, options = {} )->
      L.Util.setOptions @, options
      super(control, map)

      @references = new C.OverlayLayers(map, @options)
      @add(@options.overlays, 'tiles') unless !@options.overlays.length
      @add([@options.series, @options.layers], 'series') if @options.series?

    add: (layers, type) ->
      newLayers = @references.add(layers, type)

      for name, layer of newLayers
        @getControl().addOverlay(layer, name)

  class C.Controls.Scale extends C.Controls
    options:
      position: "bottomright"
      imperial: false
      maxWidth: 200

    constructor: ( map, options = {} ) ->
      super(map)
      L.Util.setOptions @, options
      @control = new L.Control.Scale(@options)

    getControl: ->
      @control

  class C.Controls.Edit extends C.Controls
    options:
      label: undefined
      edit: undefined
      reactiveMeasure: true
      draw:
        edit:
          featureGroup: undefined
          remove: false
          edit:
            color: "#A40"
            popup: false
        draw:
          marker: false
          circlemarker: false
          polyline: false
          rectangle: false
          circle: false
          polygon:
            allowIntersection: false
            showArea: false
          # reactiveMeasure: true

    constructor: ( map, options = {} ) ->
      super(map)
      L.Util.setOptions @, options

      @editionLayer = L.geoJson()

      @options.draw.edit.featureGroup = @editionLayer

      map.addLayer @editionLayer

      @control = new L.Control.Draw(@options.draw)

      @initHooks()

    initHooks: (->)

    getControl: ->
      @control

    getLayer: ->
      @editionLayer

    addLayer: (layer) ->
      @getLayer().addData layer.toGeoJSON()

    addTo: (control) ->
      control.addOverlay @getLayer(), @options.label

  class C.Controls.Edit.Snap extends C.Controls
    options:
      snap:
        polyline:
          guideLayers: []
          snapDistance: 5
        polygon:
          guideLayers: []
          snapDistance: 5

    constructor: (map, control, options = {}) ->
      super(map)
      L.Util.setOptions @, options

      control.getControl().setDrawingOptions(@options.snap)

      @initHooks()

    initHooks: (->)

  class C.Controls.Edit.ReactiveMeasure extends C.Controls
    options:
      reactiveMeasure:
        position: 'bottomright'
        metric: true
        feet: false
        tooltip: true

    constructor: (map, control, options = {}) ->
      super(map)
      L.Util.setOptions @, options

      @control = new L.ReactiveMeasureControl(control.getLayer(), @options.reactiveMeasure)

      @initHooks()

    initHooks: (->)

    getControl: ->
      @control

)(window.Cartography = window.Cartography || {}, jQuery)
