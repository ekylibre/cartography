# @turf/bbox-polygon

<!-- Generated by documentation.js. Update this documentation by updating the source code. -->

## bboxPolygon

Takes a bbox and returns an equivalent [polygon](https://tools.ietf.org/html/rfc7946#section-3.1.6).

**Parameters**

-   `bbox` **[BBox](https://tools.ietf.org/html/rfc7946#section-5)** extent in [minX, minY, maxX, maxY] order

**Examples**

```javascript
var bbox = [0, 0, 10, 10];

var poly = turf.bboxPolygon(bbox);

//addToMap
var addToMap = [poly]
```

Returns **[Feature](https://tools.ietf.org/html/rfc7946#section-3.2)&lt;[Polygon](https://tools.ietf.org/html/rfc7946#section-3.1.6)>** a Polygon representation of the bounding box

<!-- This file is automatically generated. Please don't edit it directly:
if you find an error, edit the source file (likely index.js), and re-run
./scripts/generate-readmes in the turf project. -->

---

This module is part of the [Turfjs project](http://turfjs.org/), an open source
module collection dedicated to geographic algorithms. It is maintained in the
[Turfjs/turf](https://github.com/Turfjs/turf) repository, where you can create
PRs and issues.

### Installation

Install this module individually:

```sh
$ npm install @turf/bbox-polygon
```

Or install the Turf module that includes it as a function:

```sh
$ npm install @turf/turf
```