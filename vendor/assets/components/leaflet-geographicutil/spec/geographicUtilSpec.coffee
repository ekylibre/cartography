describe 'L.GeographicUtil', ->
  it 'should return measure of a polygon', ->
    points = [[0,0], [1,0], [1,1], [0,1]]
    perimeter = 443770.91724830196
    area = 12308778361.469452

    g = L.GeographicUtil.Polygon points
    expect(g.perimeter).toEqual(perimeter)
    expect(g.area).toEqual(area)

  it 'should return measure of a polyline', ->
    points = [[0,0], [1,0], [1,1], [0,1]]
    perimeter = 332451.42645502836

    g = L.GeographicUtil.Polygon points, true
    expect(g.perimeter).toEqual(perimeter)
