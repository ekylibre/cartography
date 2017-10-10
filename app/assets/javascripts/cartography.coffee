((C, $) ->
  "use strict"

  class C.BaseClass
    constructor: (map) ->
      @map = map

  class C.Control extends C.BaseClass
    constructor: (map) ->
      super(map)

  class C.Layer extends C.BaseClass
    constructor: (map) ->
      super(map)

  class C.Layers extends C.Layer
    constructor: (map) ->
      super(map)

  class C.Map extends C.BaseClass
    options:
      box:
        height: '400px'
        width: undefined
      map:
        scrollWheelZoom: false
        zoomControl: false
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
      #TODO

    controls: ->
      @controls = new C.Controls(@map, @options)

      layersControl = new C.Controls.Layers(@map, @options)
      control = layersControl.getControl()
      @controls.add 'layers', control

    setView: ->
      @map.fitWorld({ maxZoom: 21 })

  class C.Controls extends C.Control
    controls: {}

    constructor: (map) ->
      super(map)

    add: (id, control) ->
      @controls[id] = control
      @map.addControl control


    remove: (id, control) ->
      @controls[id] = undefined


  class C.Controls.Layers extends C.Controls

    constructor: ( map, options = {} ) ->
      super(map)

      L.Util.setOptions @, options

      backgroundLayers = new C.BackgroundLayers(map, @options).getLayers()

      overlayLayers = new C.OverlayLayers(map, @options).getLayers()
      @control = new L.Control.Layers(backgroundLayers, overlayLayers)

    getControl: ->
      @control

  class C.BackgroundLayers extends C.Layers
    options:
      backgrounds: ['OpenStreetMap.HOT','OpenStreetMap.Mapnik', 'Thunderforest.Landscape', 'Esri.WorldImagery']

    backgroundLayers: {}

    constructor: ( map, options = {} )->
      super(map)

      L.Util.setOptions @, options

      for layer, index in @options.backgrounds
        @backgroundLayers[layer] = L.tileLayer.provider(layer)

      @setActiveBackground(0)

    getLayers: ->
      @backgroundLayers

    setActiveBackground: (index) ->
      @map.addLayer(@backgroundLayers[Object.keys(@backgroundLayers)[index]])


  class C.OverlayLayers extends C.Layers
    options:
      minZoom: 0
      maxZoom: 25
      overlays: []

    overlayLayers: {}

    constructor: ( map, options = {} )->
      super(map)

      L.Util.setOptions @, options

      return if !@options.overlays.length

      for layer, index in @options.overlays
        opts = {}
        opts['attribution'] = layer.attribution if layer.attribution?
        opts['minZoom'] = layer.minZoom || @options.minZoom
        opts['maxZoom'] = layer.maxZoom || @options.maxZoom
        opts['subdomains'] = layer.subdomains if layer.subdomains?
        opts['opacity'] = (layer.opacity / 100).toFixed(1) if layer.opacity? and !isNaN(layer.opacity)
        opts['tms'] = true if layer.tms

        @overlayLayers[layer.name] =  L.tileLayer(layer.url, opts)

    getLayers: ->
      @overlayLayers


)(window.Cartography = window.Cartography || {}, jQuery)
