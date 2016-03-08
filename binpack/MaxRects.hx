package binpack;

import binpack.Rectangle;
/*
	Implements different bin packer algorithms that use the MAXRECTS data structure.
	See http://clb.demon.fi/projects/even-more-rectangle-bin-packing
 
	Author: Jukka Jylänki
		- Original
	
	Author: Claus Wahlers
		- Ported to ActionScript3
	
	Author: Tony DiPerna
	    - Ported to HaXe, optimized

	This work is released to Public Domain, do whatever you want with it.
*/

private class ScoreResult {
	public var score1: Float;
	public var score2: Float;
	public var node: Rectangle;
	public inline function new( score1, score2, node ) {
		this.score1 = score1;
		this.score2 = score2;
		this.node = node;
	}
}

class MaxRects {
	//public var usedRectangles:FastList<Rectangle>;
	public var freeRectangles(default,null): Array<Rectangle>;
	public var usedRectangles(default,null): Array<Rectangle>;
	public var binWidth(default,null): Float;
	public var binHeight(default,null): Float;
	public var allowRotation(default,null): Bool;	
	public var occupancy(get,null): Float;

	public function new( width: Float, height: Float, allowRotation: Bool = false ) {
		this.binWidth = width;
		this.binHeight = height;
		this.freeRectangles = [new Rectangle(0, 0, width, height)];
		this.usedRectangles = [];
		this.allowRotation = allowRotation;
	}

	public inline function get_occupancy() {
		var sq = 0.0;
		for ( rect in usedRectangles ) {
			sq += rect.width * rect.height;
		}
		return sq / (binWidth*binHeight);
	}

	public function insert( width: Float, height: Float ): Rectangle {
		var newNode = quickFindPositionForNewNodeBestAreaFit( width, height );
		
		if (newNode.height == 0) {
			return newNode;
		}
		
		var numRectanglesToProcess = freeRectangles.length;
		var i = 0;
		while ( i < numRectanglesToProcess ) {
			if ( splitFreeNode( freeRectangles[i], newNode )) {
				freeRectangles.splice( i, 1 );
				--numRectanglesToProcess;
				--i;
			}
			i++;
		}
		
		pruneFreeList();
		usedRectangles.push( newNode );

		return newNode;
	}
	
	static var MAX_BEST_SCORE = Math.POSITIVE_INFINITY;

	public function batchInsert( ws: Array<Float>, hs: Array<Float> ): Bool {
		if ( ws.length == hs.length ) {
			var rects = new Array<Rectangle>();
			for (i in 0...ws.length ) {
				var newRect = new Rectangle( 0, 0, ws[i], hs[i] );
				rects.push( newRect );
			}

			var result = new ScoreResult( 0, 0, null );
			while ( rects.length > 0 ) {
				var bestScore1 = MAX_BEST_SCORE;
				var bestScore2 = MAX_BEST_SCORE;
				var bestNode: Rectangle = null;
				var bestNodeIndex = - 1;

				for ( i in 0...rects.length ) {
					var rect = rects[i];
					newNodeBestAreaFit( result, rect.width, rect.height );
					
					var score1 = result.score1;
					var score2 = result.score2;
					var newNode = result.node;
					if ( score1 < bestScore1 || (score1 == bestScore1 && score2 < bestScore2 )) {
						bestScore1 = score1;
						bestScore2 = score2;
						bestNode = newNode;
						bestNodeIndex = i;
					}
				}

				if ( bestNode != null ) {
					placeRect( bestNode );
					rects.splice( bestNodeIndex, 1 );
				} else {
					return false; 
				}
			}
			return true;
		} else {
			return false;
		}
	}

	function placeRect( node: Rectangle ) {
		var i = 0;
		var len = freeRectangles.length;
		while ( i < len ) {
			if ( splitFreeNode( freeRectangles[i], node )) {
				freeRectangles.splice( i, 1 );
				i -= 1;
				len -= 1;
			}
			i += 1;	
		}
		pruneFreeList();
		usedRectangles.push( node );
	}

	static inline function abs( a: Float ) return a >= 0 ? a : -a;
	static inline function min( a: Float, b: Float ) return a > b ? a : b;

	function newNodeBestAreaFit( result: ScoreResult, width: Float, height: Float ) {
		var bestNode = new Rectangle( 0, 0, 0, 0 );

		var bestAreaFit = MAX_BEST_SCORE; 
		var bestShortSideFit = MAX_BEST_SCORE;

		for ( freeRect in freeRectangles ) {
			var areaFit = freeRect.width * freeRect.height - width * height;

			// Try to place the rectangle in upright (non-flipped) orientation.
			if ( freeRect.width >= width && freeRect.height >= height ) {
				var leftoverHoriz = abs( freeRect.width - width );
				var leftoverVert = abs( freeRect.height - height );
				var shortSideFit = min( leftoverHoriz, leftoverVert );

				if ( areaFit < bestAreaFit || ( areaFit == bestAreaFit && shortSideFit < bestShortSideFit )) {
					bestNode.x = freeRect.x;
					bestNode.y = freeRect.y;
					bestNode.width = width;
					bestNode.height = height;
					bestShortSideFit = shortSideFit;
					bestAreaFit = areaFit;
				}
			}

			if ( allowRotation && freeRect.width >= height && freeRect.height >= width) {
				var leftoverHoriz = abs( freeRect.width - height );
				var leftoverVert = abs( freeRect.height - width );
				var shortSideFit = min( leftoverHoriz, leftoverVert );

				if ( areaFit < bestAreaFit || ( areaFit == bestAreaFit && shortSideFit < bestShortSideFit )) {
					bestNode.x = freeRect.x;
					bestNode.y = freeRect.y;
					bestNode.width = height;
					bestNode.height = width;
					bestShortSideFit = shortSideFit;
					bestAreaFit = areaFit;
				}
			}
		}

		result.score1 = bestAreaFit;
	 	result.score2 = bestShortSideFit;
		result.node = bestNode;
	}

	inline function quickFindPositionForNewNodeBestAreaFit( width: Float, height: Float ): Rectangle {
		var score = Math.POSITIVE_INFINITY;
		var bestNode = new Rectangle( 0, 0, 0, 0 );
		for ( r in freeRectangles ) {
		// Try to place the rectangle in upright (non-flipped) orientation.
			if (r.width >= width && r.height >= height) {
				var areaFit = r.width * r.height - width * height;
				if (areaFit < score) {
					bestNode.x = r.x;
					bestNode.y = r.y;
					bestNode.width = width;
					bestNode.height = height;
					score = areaFit;
				}
			}
		}
		
		return bestNode;
	}
	
	function splitFreeNode( freeNode: Rectangle, usedNode: Rectangle ): Bool {
		// Test with SAT if the rectangles even intersect.
		if ( !usedNode.intersects( freeNode )) {
			return false;
		}

		var newRect: Rectangle = null;

		if ( usedNode.left < freeNode.right && usedNode.right > freeNode.left ) {
			// New node at the top side of the used node.
			if ( usedNode.bottom > freeNode.bottom && usedNode.bottom < freeNode.top ) {
				newRect = new Rectangle( freeNode.left, freeNode.bottom, freeNode.width, usedNode.y - freeNode.y );
				freeRectangles.push( newRect );
			}
			// New node at the bottom side of the used node.
			if ( usedNode.top < freeNode.top ) {
				newRect = new Rectangle( freeNode.left, usedNode.top, freeNode.width, freeNode.top - usedNode.top );
				freeRectangles.push( newRect );
			}
		}
		
		if ( usedNode.bottom < freeNode.top && usedNode.top > freeNode.bottom ) {
			// New node at the left side of the used node.
			if ( usedNode.left > freeNode.left && usedNode.left < freeNode.right ) {
				newRect = new Rectangle( freeNode.left, freeNode.bottom, usedNode.left - freeNode.left, freeNode.height );
				freeRectangles.push( newRect );
			}
			// New node at the right side of the used node.
			if ( usedNode.right < freeNode.right ) {
				newRect = new Rectangle( usedNode.right, freeNode.bottom, freeNode.right - usedNode.right, freeNode.height );
				freeRectangles.push( newRect );
			}
		}
		
		return true;
	}
/*
	function pruneFreeList() {
		// Go through each pair and remove any rectangle that is redundant.
		var i = 0;
		var j = 0;
		var len = freeRectangles.length;
		while ( i < len ) {
			j = i + 1;
			var tmpRect = freeRectangles[i];
			while (j < len) {
				var tmpRect2 = freeRectangles[j];
				if ( tmpRect2.contains( tmpRect )) {
					freeRectangles.splice( i, 1 );
					--i;
					--len;
					break;
				}
				if ( tmpRect.contains( tmpRect2 )) {
					freeRectangles.splice( j, 1 );
					--len;
					--j;
				}
				j++;
			}
			i++;
		}
	}
 */
	function pruneFreeList() {
		var i = 0;
		var len = freeRectangles.length;

		while ( i < len ) {
			var irect = freeRectangles[i];	
			var j = i + 1;
			while ( j < len ) {
				var jrect = freeRectangles[j];
				if ( jrect.contains( irect )) {
					len -= 1;
					if ( i < len ) {
						freeRectangles[i] = freeRectangles[len];
						i -= 1;
					}
					break;
				}	
				if ( irect.contains( jrect )) {
					len -= 1;
					if ( j < len ) {
						freeRectangles[j] = freeRectangles[len];
						j -= 1;
					} 
				}
				j += 1;
			}
			i += 1;
		}

		freeRectangles.splice( len, freeRectangles.length - len );
	}
}
