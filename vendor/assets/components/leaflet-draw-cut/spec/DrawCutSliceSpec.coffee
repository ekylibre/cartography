describe 'DrawCutSlice', ->

  beforeEach ->
    @map = new L.Map(document.createElement('div')).setView([0, 0], 15)

  it 'should split a simple polygon', ->
    options = {}
    options.featureGroup = new L.FeatureGroup()
    klass = new L.Cut.Polyline(@map, options)

    poly = new L.polygon []
    poly.fromTurfFeature  FIXTURES['simple'].features[0]

    splitter = new L.polyline []
    splitter.fromTurfFeature FIXTURES['simple'].features[1]

    splitResult = klass._slice(poly, splitter)
    expect(JSON.stringify(splitResult.toGeoJSON())).toBe(JSON.stringify(EXPECTATIONS['simple']))

  it 'should split a complex polygon', ->
    options = {}
    options.featureGroup = new L.FeatureGroup()
    klass = new L.Cut.Polyline(@map, options)

    poly = new L.polygon []
    poly.fromTurfFeature  FIXTURES['complex'].features[0]

    splitter = new L.polyline []
    splitter.fromTurfFeature FIXTURES['complex'].features[1]

    splitResult = klass._slice(poly, splitter)
    expect(JSON.stringify(splitResult.toGeoJSON())).toBe(JSON.stringify(EXPECTATIONS['complex']))

  it 'should split a polygon with hole 1', ->
    options = {}
    options.featureGroup = new L.FeatureGroup()
    klass = new L.Cut.Polyline(@map, options)

    poly = new L.polygon []
    poly.fromTurfFeature  FIXTURES['holes1'].features[0]

    splitter = new L.polyline []
    splitter.fromTurfFeature FIXTURES['holes1'].features[1]

    splitResult = klass._slice(poly, splitter)
    expect(JSON.stringify(splitResult.toGeoJSON())).toBe(JSON.stringify(EXPECTATIONS['holes1']))

  it 'should split a polygon with multiples holes 2', ->
    options = {}
    options.featureGroup = new L.FeatureGroup()
    klass = new L.Cut.Polyline(@map, options)

    poly = new L.polygon []
    poly.fromTurfFeature  FIXTURES['holes2'].features[0]

    splitter = new L.polyline []
    splitter.fromTurfFeature FIXTURES['holes2'].features[1]

    splitResult = klass._slice(poly, splitter)
    expect(JSON.stringify(splitResult.toGeoJSON())).toBe(JSON.stringify(EXPECTATIONS['holes2']))

  it 'should split a polygon with multiples holes 3', ->
    options = {}
    options.featureGroup = new L.FeatureGroup()
    klass = new L.Cut.Polyline(@map, options)

    poly = new L.polygon []
    poly.fromTurfFeature  FIXTURES['holes3'].features[0]

    splitter = new L.polyline []
    splitter.fromTurfFeature FIXTURES['holes3'].features[1]

    splitResult = klass._slice(poly, splitter)
    expect(JSON.stringify(splitResult.toGeoJSON())).toBe(JSON.stringify(EXPECTATIONS['holes3']))

  it 'should split a polygon into multiple polygons', ->
    options = {}
    options.featureGroup = new L.FeatureGroup()
    klass = new L.Cut.Polyline(@map, options)

    poly = new L.polygon []
    poly.fromTurfFeature  FIXTURES['multiple'].features[0]

    splitter = new L.polyline []
    splitter.fromTurfFeature FIXTURES['multiple'].features[1]

    splitResult = klass._slice(poly, splitter)
    expect(JSON.stringify(splitResult.toGeoJSON())).toBe(JSON.stringify(EXPECTATIONS['multiple']))
