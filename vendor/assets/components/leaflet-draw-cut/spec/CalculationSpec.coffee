turf = require '@turf/helpers'

describe 'Calculation', ->

  beforeEach ->
    @map = new L.Map(document.createElement('div')).setView([0, 0], 15)

  it 'should return a shape resulting of the union between two overlaping shapes', ->
    smallPolygon1 = FIXTURES['smallPolygon1'].features[0].geometry
    smallPolygon2 = FIXTURES['smallPolygon2'].features[0].geometry
    union = L.Calculation.union([smallPolygon1, smallPolygon2])
    expectedUnion = EXPECTATIONS['smallPolygonUnion'].features[0].geometry

    expect(union.geometry).toEqual(expectedUnion)

  it 'should return a shape resulting of the difference between two shapes', ->
    largePolygon = FIXTURES['largePolygon'].features[0].geometry
    smallPolygon = FIXTURES['smallPolygon1'].features[0].geometry
    difference = L.Calculation.difference(largePolygon, smallPolygon)
    expectedDifference = EXPECTATIONS['smallPolygonDifference'].features[0].geometry

    expect(difference.geometry).toEqual(expectedDifference)
