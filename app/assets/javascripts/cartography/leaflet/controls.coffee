((C) ->
  "use strict"

  class L.Control.SnapEdit extends L.Control
    options:
      position: 'topleft'
      draw: {}

    constructor: (options) ->
      C.Util.setOptions @, options
      super options
      toolbar = undefined
      @_toolbar = {}
      if L.SnapEditToolbar
        @options.snap.guideLayers = @options.snap.polygon.guideLayers

        @_toolbar = new L.SnapEditToolbar @options
      L.toolbar = this
      return

    onAdd: (map) ->
      container = L.DomUtil.create('div', 'leaflet-draw')
      topClassName = 'leaflet-draw-toolbar-top'
      toolbarContainer = @_toolbar.addToolbar(map)
      if toolbarContainer
        L.DomUtil.addClass toolbarContainer.childNodes[0], topClassName
        container.appendChild toolbarContainer
      container

    onRemove: ->
      @_toolbar.removeToolbar()

  class L.Control.LayerSelection extends L.Control
    @_toolbar: {}

    options:
      position: 'topleft'
      featureGroup: undefined

    constructor: (options) ->
      C.Util.setOptions @, options
      super options

      if L.LayerSelectionToolbar && !@_toolbar
        @_toolbar = new L.LayerSelectionToolbar @options

      return

    onAdd: (map) ->
      container = L.DomUtil.create('div', 'leaflet-draw leaflet-control-layer-selection')
      topClassName = 'leaflet-draw-toolbar-top'
      toolbarContainer = @_toolbar.addToolbar(map)
      if toolbarContainer
        L.DomUtil.addClass toolbarContainer.childNodes[0], topClassName
      container.appendChild toolbarContainer
      container

    onRemove: ->
      @_toolbar.removeToolbar()

  class L.Control.Cut extends L.Control
    @_toolbar: {}

    options:
      position: 'topleft'
      featureGroup: undefined
      panel: true

    constructor: (options) ->
      C.Util.setOptions @, options
      super options

      if L.CutToolbar && !@_toolbar
        @_toolbar = new L.CutToolbar @options

      if @options.panel
        new L.Control.ControlPanel.Cut @_toolbar

    onAdd: (map) ->
      container = L.DomUtil.create('div', 'leaflet-draw leaflet-control-cut')
      topClassName = 'leaflet-draw-toolbar-top'
      toolbarContainer = @_toolbar.addToolbar(map)
      if toolbarContainer
        L.DomUtil.addClass toolbarContainer.childNodes[0], topClassName
      container.appendChild toolbarContainer
      container

    onRemove: ->
      @_toolbar.removeToolbar()

  class L.Control.ControlPanel.Cut extends L.Control.ControlPanel

    onAdd: (map) ->
      super map
      @addProperties()
      @_container

    addProperties: ->
      @_map.on L.Cutting.Polyline.Event.CREATED, @_addCreatedPolygons, @

    _addCreatedPolygons: (e) ->

      container = L.DomUtil.create 'div', 'property', @_propertiesContainer

      containerTitle = L.DomUtil.create 'div', 'property-title', container
      containerTitle.innerHTML = "Surfaces"

      @_areaContainer = L.DomUtil.create 'div', 'property-content', container

      @_updateArea(e)

      @_map.on L.Cutting.Polyline.Event.UPDATED, @_updateArea, @

    _updateArea: (e) ->
      layers = e.layers

      L.DomUtil.empty(@_areaContainer)

      for layer in layers
        legendRow = L.DomUtil.create 'div', 'legend-row', @_areaContainer
        legend = L.DomUtil.create 'div', 'legend', legendRow
        area = L.DomUtil.create("div", 'legend-area', legendRow)
        # layer.options.fillColor

        if typeof layer.getLatLngs is 'function'
          legend.style.backgroundColor = layer.options.fillColor
          latlngs = layer.getLatLngs()
        else
          legend.style.backgroundColor = layer.getLayers()[0].options.fillColor
          latlngs = layer.getLayers()[0].getLatLngs()

        area.innerHTML = L.GeometryUtil.readableArea(L.GeometryUtil.geodesicArea(latlngs[0]), true)

)(window.Cartography = window.Cartography || {})
