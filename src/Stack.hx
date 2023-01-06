package;

class Stack<T>
{
	private final data:Array<T>;

	public var length(get, null):Int;
	public var top(get, null):T;

	public function new()
	{
		data = new Array<T>();
	}

	function get_length():Int
	{
		return data.length;
	}

	function get_top():T
	{
		if(data.length == 0)
		{
			return null;
		}
		else
		{
			return data[data.length - 1];
		}
	}

	public function pop():Void
	{
		data.pop();
	}

	public function push(t:T):Void
	{
		data.push(t);
	}

	public inline function empty():Bool
	{
		return data.length == 0;
	}
}
