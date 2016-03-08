package binpack;

import haxe.ds.Vector;

abstract Rectangle(Vector<Float>) {
	public var x(get,set): Float;
	public var y(get,set): Float;
	public var width(get,set): Float;
	public var height(get,set): Float;
	public var top(get,set): Float;
	public var bottom(get,set): Float;
	public var left(get,set): Float;
	public var right(get,set): Float;
	
	public inline function new( x: Float, y: Float, width: Float, height: Float ) {
		this = new Vector<Float>( 4 );
		this[0] = x;
		this[1] = y;
		this[2] = width;
		this[3] = height;
	}

	public inline function clone() {
		return new Rectangle( this[0], this[1], this[2], this[3] );
	}

	public inline function get_x() return this[0];
	public inline function get_y() return this[1];
	public inline function get_width() return this[2];
	public inline function get_height() return this[3];
	public inline function set_x( x: Float ) return this[0] = x;
	public inline function set_y( y: Float ) return this[1] = y;
	public inline function set_width( width: Float ) return this[2] = width;
	public inline function set_height( height: Float ) return this[3] = height;
	
	public inline function get_left() return get_x();
	public inline function get_bottom() return get_y();
	public inline function get_right() return get_x() + get_width();
	public inline function get_top() return get_y() + get_height();
	
	public inline function set_left( left: Float ) return set_x( left );
	public inline function set_bottom( bottom: Float ) return set_y( bottom );
	public inline function set_right( right: Float ) return set_x( right - get_width());
	public inline function set_top( top: Float ) return set_y( top - get_height());

	public inline function contains( other: Rectangle ) {
		return left <= other.left && bottom <= other.bottom && right >= other.right && top >= other.top;
	}

	public inline function intersects( other: Rectangle ) {
		return left < other.right && right > other.left && bottom < other.top && top > other.bottom;
	}

	public inline function collides( other: Rectangle ) {
		return left <= other.right && right >= other.left && bottom <= other.top && top >= other.bottom;
	}
}

