L = require('leaflet')
GeographicLib = require("geographiclib")

class L.GeographicUtil
  @Polygon: (points, polyline = false) -> # (Array of [lat,lng] pair)
    geod = GeographicLib.Geodesic.WGS84
    
    poly = geod.Polygon(false)
    for point in points
      poly.AddPoint point[0], point[1]

    poly = poly.Compute(false, true)

    poly2 = geod.Polygon(true)
    for point in points
      poly2.AddPoint point[0], point[1]

    poly2 = poly2.Compute(false, true)

    extrapolatedPerimeter: poly.perimeter, extrapolatedArea: Math.abs(poly.area), perimeter: poly2.perimeter

# Use Karney distance formula
# ([lat, lng], [lat, lng]) -> Number (in meters)
  @distance: (a, b) ->
    geod = GeographicLib.Geodesic.WGS84
    r = geod.Inverse(a[0], a[1], b[0], b[1])
    r.s12.toFixed(3)
