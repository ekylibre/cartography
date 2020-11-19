#= require cartography/events
#= require cartography/util
#= require cartography/base
#= require cartography/controls
#= require cartography/layers
#= require cartography/layers/simple

((C) ->
  "use strict"

  class C.Map extends C.BaseClass
    @IDS: 0
    options:
      box:
        height: '85vh'
        width: undefined
      multiSerie: false
      map:
        scrollWheelZoom: true
        zoomControl: false
        attributionControl: true
        setDefaultBackground: false
        setDefaultOverlay: false
        dragging: true
        touchZoom: true
        doubleClickZoom: true
        boxZoom: true
        tap: true
      controls:
        draw: false
        cut: false
        layers: true
        backgrounds: true
        overlays: true
        edit: true
        snap: true
        reactiveMeasure: true
        selection: false
        locking: false
        zoom: true
        home: true
        scale: true
        fullscreen: false
      snap:
        panel:
          surfaceProperty: 'Surface'
        polygon:
          snapDistance: 15
          snapOriginDistance: 15
      cut:
        cycling: 2
        panel:
          title: 'Splitter tool'
          animatedHelper: undefined
          surfacesProperty: 'Surfaces'
      merge:
        panel:
          title: 'Merger tool'
          animatedHelper: undefined
      draw:
        panel:
          title: 'Create plot'
          coordinatesProperty: 'Coordinates'
          animatedHelper: undefined
          ignoreActions: true
      edit:
        selectedPathOptions:
          dashArray: null
          fill: true
          color: '#1195F5'
          fillColor: '#1195F5'
          opacity: 1
          fillOpacity: 0.35
          maintainColor: false
        panel:
          title: 'Edit plot'
          animatedHelper: undefined
      remove: false
      controlLayers:
        position: 'topleft'
      zoom:
        zoomInTitle: 'Zoom in'
        zoomOutTitle: 'Zoom out'

    constructor: (id, options = {}) ->
      C.Util.setOptions @, options

      # Merge drawLocal to forward translations through options.
      _.merge @options, L.drawLocal

      @baseElement = L.DomUtil.get(id)
      @baseElement.setAttribute "data-map-id", @constructor.IDS
      @constructor.IDS++

      @mapElement = L.DomUtil.create('div', 'map', @baseElement)

      @map = L.map(@mapElement, @options.map)

      @setMode @options.mode

      @resize()

      @controls()

      @initHooks()

    resize: ->
      if @options.box? and @options.box.height?
        @mapElement.style.height = @options.box.height
      if @options.box? and @options.box.width?
        @mapElement.style.width = @options.box.width

    initHooks: ->

      @getMap().on L.Draw.Event.CREATED, (e) =>
        return unless e.layerType == "polygon" or e.layerType is undefined

        feature = if e.layer instanceof L.Layer
        then e.layer.toGeoJSON(17)
        else e.layer

        @getFeatureGroup(name: "edition").addData(feature)

        uuid = feature.properties.uuid
        type = feature.properties.type = @getMode()

        layer = @getFeatureGroup(name: "edition").getLayers()[..].pop()
        centroid = layer.getCenter()
        area = L.GeometryUtil.geodesicArea(layer.getLatLngs()[0])

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

      onSplitChange = (e) =>
        data = {}
        data['splitter'] = e.splitter
        data['old'] = {uuid: e.parent.feature.properties.uuid, name: e.parent.feature.properties.name}
        data['new'] = e.layers.map (layer) ->
          p = layer.feature.properties
          measure = layer.getMeasure()

          { num: p.num, area: measure.extrapolatedArea, perimeter: measure.extrapolatedPerimeter, color: p.color, shape: layer.toGeoJSON(17) }

        @getMap().fire C.Events.split.change, data: data

      @getMap().on L.Cutting.Polyline.Event.CREATED, onSplitChange, @
      @getMap().on L.Cutting.Polyline.Event.UPDATED, onSplitChange, @

      @getMap().on L.Cutting.Polyline.Event.CUTTING, (e) =>
        @getMap().fire C.Events.split.cutting, data: perimeter: e.perimeter

      @getMap().on L.SnapEditing.Event.CHANGE, (e) =>
        if e.layer.getLatLngs().constructor.name is 'Array'
          latlngs = e.layer.getLatLngs()[0]
        else
          latlngs = e.layer.getLatLngs()

        area = L.GeometryUtil.geodesicArea(latlngs)
        feature = e.layer.toGeoJSON(17)

        uuid = feature.properties.uuid
        type = feature.properties.type = @getMode()

        centroid = e.layer.getCenter()

        @getMap().fire C.Events.edit.change, data: { uuid: uuid, type: type, shape: feature, area: area, centroid: centroid }


    controls: ->
      @controls = new C.Controls(@getMap(), @options)

      @controls.register 'layers', false, =>
        new C.Controls.Layers(undefined, @getMap(), @options)
      , =>
        @controls.register 'backgrounds', false, =>
          new C.Controls.BaseLayers(@controls.get('layers').getControl(), @getMap(), @options)

        @controls.register 'overlays', false, =>
          new C.Controls.OverlayLayers(@controls.get('layers').getControl(), @getMap(), @options)
        , =>
          return unless @options.controls.snap?
          layers = @controls.get('overlays').getLayers()
          @options.snap.polygon.guideLayers = Object.values(layers)

        if @options.controls.backgrounds
          @controls.add 'backgrounds'

        if @options.controls.overlays
          @controls.add 'overlays'

      @controls.register 'zoom', true, =>
        new C.Controls.Zoom(@getMap(), @options.zoom)

      @controls.register 'home', true, =>
        new C.Controls.Home(@getMap(), home: { featureGroup: @getFeatureGroup() } )

      @controls.register 'draw', true, =>
        new C.Controls.Draw(@getMap(), @options)

      @controls.register 'edit', true, =>
        C.Util.setOptions @, edit: {featureGroup: @getFeatureGroup()}
        new C.Controls.Edit(@getMap(), @options)
      , =>
        return unless @options.controls.reactiveMeasure?
        @controls.register 'measure', true, =>
          new C.Controls.Edit.ReactiveMeasure(@getMap(), @controls.get('edit'), @options)
        @controls.add 'measure'
        @removeControl 'edit'

      @controls.register 'scale', true, =>
        new C.Controls.Scale(@getMap(), @options)

      @controls.register 'selection', false, =>
        new C.Controls.LayerSelection(@getMap(), {layerSelection: {featureGroup: @getFeatureGroup()}})
      , =>
        @controls.get('selection').getControl().enable()

      @controls.register 'locking', false, =>
        new C.Controls.LayerLocking(@getMap(), {layerLocking: {featureGroup: @getFeatureGroup(name: 'crops')}})
      , =>
        @controls.get('locking').getControl().enable()

      @controls.register 'shape_draw', false, =>
        unless @options.draw.allowOverlap
          layers = @controls.get('overlays').getLayers()
          @options.draw.overlapLayers = Object.values(layers)
        new C.Controls.ShapeDraw(@getMap(), @options)
      , =>
        @controls.get('shape_draw').getControl().enable()

      @controls.register 'cut', true, =>
        C.Util.setOptions @, cut: {featureGroup: @getFeatureGroup()}
        new C.Controls.Cut(@getMap(), @options)

      @controls.register 'shape_cut', false, =>
        C.Util.setOptions @, cut: {featureGroup: @getFeatureGroup()}
        new C.Controls.ShapeCut(@getMap(), @options)
      , =>
        @controls.get('shape_cut').getControl().enable()

      @controls.register 'fullscreen', true, =>
        new C.Controls.Fullscreen(@getMap(), @options)

      if @options.controls.layers
        @controls.add 'layers'

      if @options.controls.zoom
        @controls.add 'zoom'

      if @options.controls.home
        @controls.add 'home'

      if @options.controls.fullscreen
        @controls.add 'fullscreen'

      if @options.controls.edit
        @controls.add 'edit'

      if @options.controls.scale
        @controls.add 'scale'

      if @options.controls.selection
        @controls.add 'selection'

      if @options.controls.locking
        @controls.add 'locking'

      if @options.controls.draw
        @controls.add 'draw'

      if @options.controls.cut
        @controls.add 'cut'

      style = (feature) ->
        feature.properties.style ||= {}
        color: feature.properties.style.color || "#1195F5", fillOpacity: feature.properties.style.opacity || 0.35, opacity: 1, fill: true

      serie = [{edition: []}, [name: 'edition', type: 'simple', index: true, serie: 'edition', style: style]]
      @addOverlay(serie)
      @setView()

    ##### PUBLIC API ######
    setView: ->
      if @options.bounds
        bounds = @options.bounds.split(',')
        @getMap().fitBounds([[bounds[1], bounds[0]], [bounds[3], bounds[2]]],{ maxZoom: 21 })
        return
      
      if @options.multiSerie
        featureGroups = Object.values(@controls.get('overlays').getLayers())
        for featureGroup, index in featureGroups
          if  index == 0
            bounds = featureGroup.getBounds() if  index == 0
            continue
          bounds = bounds.extend(featureGroup.getBounds())
        @getMap().fitBounds(bounds)
        return

      if @getFeatureGroup().getLayers().length
        @getMap().fitBounds(@getFeatureGroup().getBounds(),{ maxZoom: 21 })
      else
        @center @defaultCenter(), 6

    setMode: (mode) ->
      @_mode = mode

    getMode: ->
      @_mode

    setOffset: (obj) ->
      @_offset = L.point obj

    resetOffset: ->
      delete @_offset

    center: (obj, zoom = 18) ->
      return unless obj.lat && obj.lng

      @getMap().setView L.latLng(obj), zoom

    _findLayerByUUID: (featureGroup, uuid) ->
      containerLayer = undefined
      featureGroup.eachLayer (layer) ->
        if layer.feature and layer.feature.properties.uuid == uuid
          containerLayer = layer
          return
      containerLayer

    select: (uuid, center = false, featureGroup = undefined, trigger = true) ->
      name = featureGroup if featureGroup
      featureGroup = @getFeatureGroup(name: name)
      layer = @_findLayerByUUID(featureGroup, uuid)
      if layer && !layer.selected
        if trigger
          layer.fire 'click'
          layer.fire 'select'
        if center
          @getMap().fitBounds layer.getBounds()

      layer

    selectMany: (uuids, center = false) ->
      layers = []
      for uuid in uuids
        featureGroup = @getFeatureGroup()
        layer = @_findLayerByUUID(featureGroup, uuid)
        if layer
          layers.push layer
          unless layer.selected
            layer.fire 'click'
      group = L.featureGroup layers
      if center && group
        @getMap().fitBounds group.getBounds()
      group

    unselectMany: (uuids) ->
      for uuid in uuids
        featureGroup = @getFeatureGroup()
        layer = @_findLayerByUUID(featureGroup, uuid)
        if layer && layer.selected
          layer.fire 'click'

    centerCollection: (uuids, center = true) ->
      layers = []
      for uuid in uuids
        featureGroup = @getFeatureGroup()
        layer = @_findLayerByUUID(featureGroup, uuid)
        if layer
          layers.push layer
      group = L.featureGroup layers
      if center && group
        @getMap().fitBounds group.getBounds()
      group

    centerLayer: (uuid, center = true, featureGroup = undefined) ->
      featureGroup = @getFeatureGroup(name: featureGroup)
      layer = @_findLayerByUUID(featureGroup, uuid)

      if center && layer
        @getMap().fitBounds layer.getBounds()

      layer

    unselect: (uuid) ->
      featureGroup = @getFeatureGroup()
      layer = @_findLayerByUUID(featureGroup, uuid)
      if layer && layer.selected
        @unhighlight(uuid)
        layer.fire 'select'

    highlight: (uuid, featureGroup = undefined) ->
      layer = @select uuid, false, featureGroup, false
      if layer
        layer.options.highlightOriginal = L.extend({}, layer.options)
        layer.setStyle color: "#D84315", fillOpacity: 0.5

    unhighlight: (uuid, featureGroup = undefined) ->
      layer = @select uuid, false, featureGroup, false
      if layer
        layer.setStyle layer.options.highlightOriginal
        delete layer.options.highlightOriginal

    destroy: (uuid, featureGroup = undefined) ->
      layer = @select uuid, false, featureGroup, false
      name = featureGroup if featureGroup
      if layer
        @getFeatureGroup(name: name).removeLayer layer

    buildControls: (name = undefined) ->
      featureGroup = @getFeatureGroup(name: name)
      return unless featureGroup && featureGroup.getLayers()
      featureGroup.eachLayer (layer) ->
        layer.onBuild.call @ if layer.onBuild and layer.onBuild.constructor.name == 'Function'

    edit: (uuid, featureGroup = undefined, options = {}) ->
      @unhighlight uuid
      layer = @select uuid, false, featureGroup, false
      if layer
        if options.cancel && layer._editToolbar
          layer._editToolbar.disable()
          @unselect layer.feature.properties.uuid
          return

        snapOptions = {polygon: guideLayers: @getFeatureGroup()}

        options = C.Util.extend @options, snap: snapOptions

        layer._editToolbar = new L.EditToolbar.SelectableSnapEdit @getMap(),
          snapOptions: options.snap
          featureGroup: @getFeatureGroup(name: featureGroup)
          selectedPathOptions: options.edit.selectedPathOptions
          disabledPathOptions: options.edit.disabledPathOptions
          poly: options.poly
        layer._editToolbar.enable layer
        layer._editToolbar._activate layer

    union: (polygons) ->
      L.Calculation.union(polygons)

    difference: (feature1, feature2) ->
      L.Calculation.difference(feature1, feature2)

    contains: (feature1, feature2) ->
      L.Calculation.contains feature1, feature2

    intersect: (feature1, feature2) ->
      L.Calculation.intersect feature1, feature2

    sync: (data, layerName, options = {}) =>

      layerGroup =  @controls.get('overlays').getLayers()[layerName]

      newLayers = new L.geoJSON()

      onAdd = (e) =>
        layerGroup.bindInit 'layeradd', onLayerAdd
        e.target.eachLayer (layer) =>
          if options.onEachFeature && options.onEachFeature.constructor.name is 'Function'
            options.onEachFeature.call @, layer

      onLayerAdd = (e) =>
        if options.onEachFeature && options.onEachFeature.constructor.name is 'Function'
          options.onEachFeature.call @, e.layer

      layerGroup.bindInit 'layeradd', onLayerAdd
      layerGroup.bindInit 'add', onAdd

      layerGroup.on 'remove', =>
        layerGroup.unbind 'layeradd', onLayerAdd

      for el in data
        if el.shape
          geojson = el.shape
          feature = L.GeoJSON.asFeature(el.shape)
          feature.properties = el
          delete feature.properties.shape
          newLayers.addData(feature)

      if layerGroup.getLayers().length
        removeList = layerGroup.getLayers().filter (layer) ->
          !newLayers.hasUUIDLayer layer

        if removeList.length
          for l in removeList
            @getMap().fire L.Selectable.Event.UNSELECT, { layer: l }
            layerGroup.removeLayer l

        addList = newLayers.getLayers().filter (layer) ->
          !layerGroup.hasUUIDLayer layer

      else
        addList = newLayers.getLayers()

      for layer in addList
        geojson = layer.toGeoJSON(17)
        layerGroup.addData(geojson)
        # newLayer = @_findLayerByUUID(layerGroup, geojson.properties.uuid)


    defaultCenter: =>
      @options.defaultCenter

    addOverlay: (serie, type = "series") =>
      @controls.get('overlays').add(serie, type)

    removeOverlay: (name) =>
      @controls.get('overlays').remove(name)

    getOverlay: (name) =>
      @controls.get('overlays').getLayer(name)

    addControl: (name) =>
      @controls.add(name)

    removeControl: (name) =>
      @controls.remove(name)

    getFeatureGroup: (options = {}) =>
      options.main ||= true

      return @controls.get('overlays').getLayers()[options.name] if options.name

      @controls.get('overlays').getMainLayer() if options.main

    clean: =>
      @getFeatureGroup(name: "edition").clearLayers()

)(window.Cartography = window.Cartography || {})
