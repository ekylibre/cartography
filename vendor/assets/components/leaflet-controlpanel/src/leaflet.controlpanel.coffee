L = require 'leaflet'
_ = require 'lodash'

class L.Control.ControlPanel extends L.Control
  options:
    position: 'bottomleft'
    className: 'leaflet-control-controlPanel'
    titleClassName: 'leaflet-control-controlPanel-title'
    propertiesClassName: 'leaflet-control-controlPanel-properties'
    actionsClassName: 'leaflet-control-controlPanel-actions'
    expanded: true
    ignoreActions: false

  constructor: (@_toolbar, options = {}) ->
    @options = _.merge @options, options
    @_toolbar.on 'enable', @addPanel, @
    @_toolbar.on 'disable', @removePanel, @

    @_actionButtons = []

  addPanel: ->
    L.DomUtil.remove @_toolbar._actionsContainer
    @_toolbar._map.addControl @

    L.DomEvent.on @_toolbar._map._container, 'keyup', @_onCancel, @


  removePanel: ->
    L.DomEvent.off @_toolbar._map._container, 'keyup', @_onCancel, @
    @_toolbar._map.removeControl @

  #Cancel drawing when the escape key is pressed
  _onCancel: (e) ->
    if e.keyCode == 27
      @_toolbar.disable()

  onAdd: (map) ->
    @_container = L.DomUtil.create 'div', @options.className
    L.DomUtil.addClass @_container, 'large' if @options.expanded

    if @options.title
      @_titleContainer = L.DomUtil.create 'div', @options.titleClassName, @_container
      @_titleContainer.innerHTML = @options.title

    @_propertiesContainer = L.DomUtil.create 'div', @options.propertiesClassName, @_container
    L.DomEvent.disableScrollPropagation @_container

    unless @options.ignoreActions
      @_actionsContainer = L.DomUtil.create 'div', @options.actionsClassName, @_container
      @_showActionsToolbar()

    @addProperties()

    @_container

  addProperties: ->
    @_addAnimatedHelper()
    @_addPointerCoordinates()

  onRemove: ->

  _createActions: (handler) ->
    container = @_actionsContainer
    buttons = @_toolbar.getActions(handler)
    l = buttons.length
    di = 0
    dl = @_actionButtons.length

    while di < dl
      @_toolbar._disposeButton @_actionButtons[di].button, @_actionButtons[di].callback
      di++
    @_actionButtons = []

    # Remove all old buttons
    while container.firstChild
      container.removeChild container.firstChild
    i = 0

    while i < l
      if 'enabled' of buttons[i] and !buttons[i].enabled
        i++
        continue

      div = L.DomUtil.create('div', 'button', container)

      button = @_toolbar._createButton(
        title: buttons[i].title
        text: buttons[i].text
        container: div
        callback: buttons[i].callback
        context: buttons[i].context)

      @_actionButtons.push
        button: button
        callback: buttons[i].callback
      i++

  _showActionsToolbar: ->
    buttonIndex = @_toolbar._activeMode.buttonIndex
    lastButtonIndex = @_toolbar._lastButtonIndex
    toolbarPosition = @_toolbar._activeMode.button.offsetTop - 1
    # Recreate action buttons on every click
    @_createActions @_toolbar._activeMode.handler
    # Correctly position the cancel button
    @_actionsContainer.style.top = toolbarPosition + 'px'
    if buttonIndex == 0
      L.DomUtil.addClass @_actionsContainer, 'leaflet-draw-actions-top'
    if buttonIndex == lastButtonIndex
      L.DomUtil.addClass @_actionsContainer, 'leaflet-draw-actions-bottom'
    @_actionsContainer.style.display = 'block'
    return

  _hideActionsToolbar: ->
    @_actionsContainer.style.display = 'none'
    L.DomUtil.removeClass @_actionsContainer, 'leaflet-draw-actions-top'
    L.DomUtil.removeClass @_actionsContainer, 'leaflet-draw-actions-bottom'
    return


  _addAnimatedHelper: () ->

    container = L.DomUtil.create 'div', 'property', @_propertiesContainer

    @_animatedHelperContainer = L.DomUtil.create 'div', 'property-content', container

    if @options.animatedHelper
      img = L.DomUtil.create 'img', 'animated-helper', @_animatedHelperContainer
      img.src = @options.animatedHelper

  _addPointerCoordinates: () ->

    container = L.DomUtil.create 'div', 'property', @_propertiesContainer

    containerTitle = L.DomUtil.create 'div', 'property-title', container
    containerTitle.innerHTML = "Coordinates"

    @_pointerCoordinatesContainer = L.DomUtil.create 'div', 'property-content', container

    @_map.on 'mousemove', @_onUpdateCoordinates, @

  _onUpdateCoordinates: (e) ->
    coordinates = e.latlng
    L.DomUtil.empty(@_pointerCoordinatesContainer)

    latRow = L.DomUtil.create 'div', 'coordinates-row', @_pointerCoordinatesContainer
    lat = L.DomUtil.create 'div', 'coordinate', latRow
    lat.innerHTML = "lat: " + coordinates.lat

    lngRow = L.DomUtil.create 'div', 'coordinates-row', @_pointerCoordinatesContainer
    lng = L.DomUtil.create 'div', 'coordinate', lngRow
    lng.innerHTML = "lng: " + coordinates.lng
