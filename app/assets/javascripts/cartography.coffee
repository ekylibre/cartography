#= require cartography/events
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
      cut:
        panel:
          title: 'Splitter tool'
          animatedHelper: 'http://placehold.it/200x150'
      merge:
        panel:
          title: 'Merger tool'
          animatedHelper: 'http://placehold.it/200x150'
      draw:
        panel:
          title: 'Create plot'
          animatedHelper: 'http://placehold.it/200x150'
          ignoreActions: true
      edit:
        panel:
          title: 'Edit plot'
          animatedHelper: 'http://placehold.it/200x150'
      remove: false
      controlLayers:
        position: 'topleft'

    constructor: (id, options = {}) ->
      C.Util.setOptions @, options

      @baseElement = L.DomUtil.get(id)
      @mapElement = L.DomUtil.create('div', 'map', @baseElement)

      @map = L.map(@mapElement, @options.map)

      @setMode @options.mode

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
        @getMap().on L.Draw.Event.DRAWSTART, =>
          @getMap().fire C.Events.new.start

        @getMap().on L.Draw.Event.DRAWSTOP, =>
          @getMap().fire C.Events.new.cancel

      @getMap().on L.Draw.Event.CREATED, (e) =>
        # @controls.get('edit').addLayer(e.layer)
        # @controls.get('edit').addTo(control) if control = @controls.get('overlays').getControl()

        # manual assignation to bypass feature add and search (we don't really need some extra properties for now)
        area = L.GeometryUtil.geodesicArea(e.layer.getLatLngs()[0])

        feature = e.layer.toGeoJSON()
        @getFeatureGroup().addData(feature)

        uuid = feature.properties.uuid
        type = feature.properties.type = @getMode()

        layer = @getFeatureGroup().getLayers()[..].pop()
        centroid = layer.getCenter()

        @getMap().fire C.Events.new.complete, data: { uuid: uuid, type: type, shape: feature, area: area, centroid: centroid }

      @getMap().on L.Selectable.Event.SELECT, (e) =>
        @getMap().fire C.Events.select.select, data: { uuid: e.layer.feature.properties.uuid }

      @getMap().on L.Selectable.Event.UNSELECT, (e) =>
        @getMap().fire C.Events.select.unselect, data: { uuid: e.layer.feature.properties.uuid }

      @getMap().on L.Selectable.Event.SELECTED, (e) ->
        console.error 'selected layers', e

      @getMap().on L.Selectable.Event.START, (e) ->
        console.error "Starting selection mode"

      @getMap().on L.Selectable.Event.STOP, (e) ->
        console.error "Stopping selection mode"

      @getMap().on L.Cutting.Polyline.Event.START, =>
        @getMap().fire C.Events.split.start

      @getMap().on L.Cutting.Polyline.Event.STOP, =>
        @getMap().fire C.Events.split.cancel

      @getMap().on L.Cutting.Polyline.Event.SELECT, (e) =>
        uuid = e.layer.feature.properties.uuid
        type = e.layer.feature.properties.type || @getMode()
        @getMap().fire C.Events.split.select, data: { uuid: uuid, type: type }

      @getMap().on L.Cutting.Polyline.Event.UPDATED, (e) =>

      @getMap().on L.Cutting.Polyline.Event.SAVED, (e) =>
        newLayers = []

        for l in e.layers
          p = l.feature.properties

          if l.getLatLngs().constructor.name is 'Array'
            latlngs = l.getLatLngs()[0]
          else
            latlngs = l.getLatLngs()

          area = L.GeometryUtil.geodesicArea(latlngs)
          centroid = l.getCenter()

          newLayers.push uuid: p.uuid, type: p.type || @getMode(), shape: l.toGeoJSON(), area: area, centroid: centroid

        @getMap().fire C.Events.split.complete, data: { old: e.oldLayer, new: newLayers }

      @getMap().on L.SnapEditing.Event.CHANGE, (e) =>
        if e.layer.getLatLngs().constructor.name is 'Array'
          latlngs = e.layer.getLatLngs()[0]
        else
          latlngs = e.layer.getLatLngs()

        area = L.GeometryUtil.geodesicArea(latlngs)
        feature = e.layer.toGeoJSON()

        uuid = feature.properties.uuid
        type = feature.properties.type = @getMode()

        centroid = e.layer.getCenter()

        @getMap().fire C.Events.edit.change, data: { uuid: uuid, type: type, shape: feature, area: area, centroid: centroid }


    controls: ->
      @controls = new C.Controls(@getMap(), @options)

      layerSelector = new C.Controls.Layers(undefined, @getMap(), @options)

      @controls.add 'layers', layerSelector, false

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

      C.Util.setOptions @, edit: {featureGroup: @getFeatureGroup()}
      @controls.add 'edit', new C.Controls.Edit(@getMap(), @options)

      @controls.add 'scale', new C.Controls.Scale(@getMap(), @options)

      if @options.controls.reactiveMeasure?
        @controls.add 'measure', new C.Controls.Edit.ReactiveMeasure(@getMap(), @controls.get('edit'), @options)


      #TODO:
      # layers = L.featureGroup(@getFeatureGroup().getLayers())
      C.Util.setOptions @, layerSelection: {featureGroup: @getFeatureGroup()}

      @controls.add 'selection', new C.Controls.LayerSelection(@getMap(), @options)

      C.Util.setOptions @, cut: {featureGroup: @getFeatureGroup()}
      @controls.add 'cut', new C.Controls.Cut(@getMap(), @options)

      C.Util.setOptions @, merge: {featureGroup: @getFeatureGroup()}
      @controls.add 'merge', new C.Controls.Merge(@getMap(), @options)

    ##### PUBLIC API ######
    setView: ->
      #TMP
      layers = @controls.get('overlays').getLayers()

      if layers[Object.keys(layers)[0]].getLayers()[0]
        @getMap().fitBounds(layers[Object.keys(layers)[0]].getLayers()[0].getBounds(),{ maxZoom: 21 })
      else
        @getMap().fitWorld()

    setMode: (mode) ->
      @_mode = mode

    getMode: ->
      @_mode

    setOffset: (obj) ->
      @_offset = L.point obj

    resetOffset: ->
      delete @_offset

    center: (obj) ->
      return unless obj.lat && obj.lng

      center = @getMap().project(obj)

      if @_offset
        offset = L.point(@_offset).round()
        center = center.add(offset)

      @getMap().flyTo @getMap().unproject(center)

    _findLayerByUUID: (featureGroup, uuid) ->
      containerLayer = undefined
      featureGroup.eachLayer (layer) ->
        if layer.feature and layer.feature.properties.uuid == uuid
          containerLayer = layer
          return
      containerLayer

    select: (uuid, center = true) ->
      featureGroup = @getFeatureGroup()
      layer = @_findLayerByUUID(featureGroup, uuid)

      if center && layer
        @center(layer.getCenter())

      layer

    unselect: (uuid) ->
      featureGroup = @getFeatureGroup()
      layer = @_findLayerByUUID(featureGroup, uuid)
      layer.fire 'click'

    highlight: (uuid) ->
      layer = @select uuid, false
      if layer
        layer.options.highlightOriginal = L.extend({}, layer.options)
        layer.setStyle color: "#D84315", fillOpacity: 0.5

    unhighlight: (uuid) ->
      layer = @select uuid, false
      if layer
        layer.setStyle layer.options.highlightOriginal
        delete layer.options.highlightOriginal

    destroy: (uuid) ->
      layer = @select uuid, true
      if layer
        @getFeatureGroup().removeLayer layer

    edit: (uuid, options = {}) ->
      layer = @select uuid, true
      if layer
        if options.cancel && layer._editToolbar
          console.error "canceling"
          @getMap().removeLayer layer._editFeatureGroup
          layer._editToolbar.disable()
          delete layer._editToolbar
          delete layer._editFeatureGroup
          return
        layer._editFeatureGroup = new L.featureGroup()
        layer._editFeatureGroup.addTo @getMap()
        # layer._editFeatureGroup.addLayer layer

        snapOptions = {polygon:
            guideLayers: @getFeatureGroup()}

        options = C.Util.extend @options, edit: {featureGroup: layer._editFeatureGroup, snap: snapOptions}

        layer._editToolbar = new L.EditToolbar.SelectableSnapEdit @getMap(),
          snapOptions: options.snap
          featureGroup: layer._editFeatureGroup
          selectedPathOptions: options.edit.selectedPathOptions
          disabledPathOptions: options.edit.disabledPathOptions
          poly: options.poly
        layer._editToolbar.enable()
        layer._editToolbar._activate layer

    sync: (data, layerName, options = {}) =>
      layerGroup =  @controls.get('overlays').getLayers()[layerName]

      layerGroup.clearLayers()
      for el in data
        if el.shape
          geojson = el.shape
          geojson.properties ||= {}
          geojson.properties.uuid ||= el.uuid
          try
            layerGroup.addData(geojson)
            newLayer = @_findLayerByUUID(layerGroup, geojson.properties.uuid)

            if options.onEachFeature.constructor.name is 'Function' && newLayer
              options.onEachFeature.call @, newLayer

      if layerGroup.getLayers().length
        @getMap().fitBounds(layerGroup.getBounds(),{ maxZoom: 21 })

    addOverlay: (serie, type = "series") =>
      @controls.get('overlays').add(serie, type)

    removeOverlay: (name) =>
      @controls.get('overlays').remove(name)

    getOverlay: (name) =>
      @controls.get('overlays').getLayer(name)

    removeControl: (name) =>
      @controls.remove(name)

    getFeatureGroup: (options = {}) =>
      options.main ||= true

      if options.name
        @controls.get('overlays').getLayers()[options.name]

      if options.main
        @controls.get('overlays').getMainLayer()

)(window.Cartography = window.Cartography || {}, jQuery)
