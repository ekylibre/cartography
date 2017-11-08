# Leaflet.ControlPanel

This plugin extends Leaflet.Draw to provide a dedicated panel to toolbars.
It allows to display extended informations for each handler.
It also override default toolbar to render actions on the panel.

Works with Leaflet 1.2.0 and Leaflet.Draw 0.4.12

## Usage

```
toolbar = L.CustomToolbar

options:
  position: 'bottomleft'
  className: 'leaflet-control-controlPanel'
  propertiesClassName: 'leaflet-control-controlPanel-properties'
  actionsClassName: 'leaflet-control-controlPanel-actions'
  expanded: true

new L.Control.ControlPanel toolbar, options

```

## Installation
  Via NPM: ```npm install leaflet-controlpanel```

  Include ```dist/leaflet.controlpanel.js``` on your page.

  Or, if using via CommonJS (Browerify, Webpack, etc.):
  ```
var L = require('leaflet')
require('leaflet-controlpanel')
```
## Development  
This plugin is powered by webpack:

* Use ```npm run watch``` to automatically rebuild while developing.
* Use ```npm test``` to run unit tests.
* Use ```npm run build``` to minify for production use, in the ```dist/```
