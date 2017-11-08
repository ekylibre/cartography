import WKTWriter from '../../io/WKTWriter';
import Coordinate from '../../geom/Coordinate';
import Double from '../../../../../java/lang/Double';
import extend from '../../../../../extend';
import Comparator from '../../../../../java/util/Comparator';
export default function IntervalRTreeNode() {
	this._min = Double.POSITIVE_INFINITY;
	this._max = Double.NEGATIVE_INFINITY;
}
extend(IntervalRTreeNode.prototype, {
	getMin: function () {
		return this._min;
	},
	intersects: function (queryMin, queryMax) {
		if (this._min > queryMax || this._max < queryMin) return false;
		return true;
	},
	getMax: function () {
		return this._max;
	},
	toString: function () {
		return WKTWriter.toLineString(new Coordinate(this._min, 0), new Coordinate(this._max, 0));
	},
	interfaces_: function () {
		return [];
	},
	getClass: function () {
		return IntervalRTreeNode;
	}
});
function NodeComparator() {}
extend(NodeComparator.prototype, {
	compare: function (o1, o2) {
		var n1 = o1;
		var n2 = o2;
		var mid1 = (n1._min + n1._max) / 2;
		var mid2 = (n2._min + n2._max) / 2;
		if (mid1 < mid2) return -1;
		if (mid1 > mid2) return 1;
		return 0;
	},
	interfaces_: function () {
		return [Comparator];
	},
	getClass: function () {
		return NodeComparator;
	}
});
IntervalRTreeNode.NodeComparator = NodeComparator;
