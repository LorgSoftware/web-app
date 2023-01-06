package;

import Types.Char;

/*
 * Read a string as a stream.
 * From: http://lisperator.net/pltut/parser/input-stream
 */
class InputStream
{
	private final input:String;
	private var position:Int = 0;
	public var line(default, null):Int = 1;
	public var column(default, null):Int = 0;

	public function new(input:String)
	{
		if(input == null)
			throw "In InputStream: input is null";
		this.input = input;
	}

	public function next():Char
	{
		var character = input.charAt(position);
		position++;
		if(character == "\n")
		{
			line++;
			column = 0;
		}
		else
			column++;
		return character;
	}

	public function peek():Char
	{
		return input.charAt(position);
	}

	public function isEOF():Bool
	{
		return peek() == "";
	}
}
