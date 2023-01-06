package;

class Node
{
	public var title:String;
	public var children:Array<Node>;
	public var units:Map<String, Unit>;

	public function new(title:String)
	{
		this.title = title;
		children = [];
		units = [];
	}
}
