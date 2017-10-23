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

)(window.Cartography = window.Cartography || {})
