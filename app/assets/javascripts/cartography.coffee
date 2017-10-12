((C, $) ->
  "use strict"

  class C.BaseClass
    constructor: (map) ->
      @map = map

    getMap: ->
      @map

  class C.Control extends C.BaseClass
    constructor: (map) ->
      super(map)

  class C.Layer extends C.BaseClass
    constructor: (map) ->
      super(map)

  class C.Layers extends C.Layer
    constructor: (map) ->
      super(map)
      @layers = {}

    getLayers: ->
      @layers

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

    constructor: (id, options = {}) ->
      L.Util.setOptions @, options

      @baseElement = L.DomUtil.get(id)
      @mapElement = L.DomUtil.create('div', 'map', @baseElement)

      @map = L.map(@mapElement, @options.map)

      #TMP
      @options.overlays = [{name: "open_weather_map.clouds", attribution: 'Weather from <a href="http://openweathermap.org/" alt="World Map and worldwide Weather Forecast online">OpenWeatherMap</a>', opacity: 100, maxZoom: 18, url: 'http://{s}.tile.openweathermap.org/map/clouds/{z}/{x}/{y}.png'}]

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




    setView: ->
      @getMap().fitWorld({ maxZoom: 21 })

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
      series: []

    constructor: ( control, map, options = {} )->
      L.Util.setOptions @, options
      super(control, map)

      @references = new C.OverlayLayers(map, @options)

      @add(@options.overlays, 'tiles') unless !@options.overlays.length
      @add(@options.series, 'series') unless !@options.series.length

    add: (layers, type) ->
      newLayers = @references.add(layers, type)

      for name, layer of newLayers
        @getControl().addOverlay(layer, name)


class C.BaseLayers extends C.Layers
  @options:
    backgrounds: []

  constructor: ( map, options = {} ) ->
    L.Util.setOptions @, options
    super(map)

  add: (layers) ->
    layers = [layers] unless layers.constructor.name is "Array"

    newLayers = {}

    for layer in layers
      newLayers[layer] = L.tileLayer.provider(layer)

    L.Util.extend(@layers, newLayers)
    newLayers
    
  class C.OverlayLayers extends C.Layers
    @options:
      overlays: []
      series: []

    constructor: ( map, options = {} ) ->
      L.Util.setOptions @, options
      super(map)

    add: (layers, type) ->
      @["add#{type}"](layers)

    addtiles: (layers) ->
      layers = [layers] unless layers.constructor.name is "Array"

      newLayers = {}

      for layer in layers
        opts = {}
        opts.attribution = layer.attribution if layer.attribution?
        opts.minZoom = layer.minZoom || @options.minZoom
        opts.maxZoom = layer.maxZoom || @options.maxZoom
        opts.subdomains = layer.subdomains if layer.subdomains?
        opts.opacity = (layer.opacity / 100).toFixed(1) if layer.opacity? and !isNaN(layer.opacity)
        opts.tms = true if layer.tms

        newLayers[layer.name] =  L.tileLayer(layer.url, opts)
        newLayers[layer.name].addTo(@getMap())

      L.Util.extend(@layers, newLayers)
      newLayers

    addseries: (layers) ->


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

)(window.Cartography = window.Cartography || {}, jQuery)
