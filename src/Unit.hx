package;

class Unit
{
	public var name:String;
	public var value:Float;
	public var isReal:Bool;
	public var isIgnored:Bool;

	public function new(name:String, value:Float, isReal:Bool=true)
	{
		this.name = name;
		this.value = value;
		this.isReal = isReal;
		isIgnored = false;
	}
}
