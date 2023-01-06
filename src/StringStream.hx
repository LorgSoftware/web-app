package;

/*
 * Stream to a given string, and keeps the column and the line position
 * synchronized with the current character the stream is currently pointing to.
 *
 * NOTE(nales, 2023-01-06): Some characters are completely ignored by Lorg so
 * we skip them here.
 */
class StringStream
{
	public static final IGNORED_CHARACTERS:Array<String> = [
		"\r", 
	];

	// The line of the last character returned by `get()`.
	public var line:Int;

	// The column of the last character returned by `get()`.
	public var column:Int;

	// The line of the character returned by `peek()`.
	public var peekLine:Int;

	// The column of the character returned by `peek()`.
	public var peekColumn:Int;

	// The current look up character index in the string.
	public var index:Int;

	public final s:String;

	public function new(stringReference:String)
	{
		line = 0;
		column = 0;
		peekLine = 1;
		peekColumn = 1;
		index = 0;
		s = stringReference;

		if(s.length == 0)
		{
			peekLine = 0;
			peekColumn = 0;
			return;
		}
		while(
			index < s.length &&
			isIgnoredCharacter(s.charAt(index))
		)
		{
			index++;
			peekColumn++;
		}
		if(!eof())
		{
			if(s.charAt(index) == '\n')
			{
				peekLine++;
				peekColumn = 0;
			}
		}
	}

	public function eof():Bool
	{
		return index >= s.length;
	}

	public function get():String
	{
		if(eof())
		{
			return "";
		}
		var c = s.charAt(index);
		line = peekLine;
		column = peekColumn;

		index++;
		peekColumn++;

		while(
			index < s.length &&
			isIgnoredCharacter(s.charAt(index))
		)
		{
			index++;
			peekColumn++;
		}

		if(!eof())
		{
			if(s.charAt(index) == '\n')
			{
				peekLine++;
				peekColumn = 0;
			}
		}
		return c;
	}

	public function peek():String
	{
		if(eof())
		{
			return "";
		}
		else
		{
			return s.charAt(index);
		}
	}

	private inline function isIgnoredCharacter(c:String):Bool
	{
		return IGNORED_CHARACTERS.indexOf(c) != -1;
	}
}
