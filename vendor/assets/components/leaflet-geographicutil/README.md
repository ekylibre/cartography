# Leaflet.GeographicUtil

This plugin provides a Leaflet helper to implement GeographicLib calculations

## Usage

```
L.GeographicUtil,Polygon(points, polyline = false)
```

## Installation
  Via NPM: ```npm install leaflet-geographicutil```

  Include ```dist/leaflet.geographicutil.js``` on your page.

  Or, if using via CommonJS (Browerify, Webpack, etc.):
  ```
var L = require('leaflet')
require('leaflet-geographicutil')
```
## Development  
This plugin is powered by webpack:

* Use ```npm run watch``` to automatically rebuild while developing.
* Use ```npm test``` to run unit tests.
* Use ```npm run build``` to minify for production use, in the ```dist/```
