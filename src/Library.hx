package;

/**
 * It exposes Lorg as a library so the user can interact with it. It is up to
 * the library user to manage its implementation in its web page.
 */
@:expose("Lorg")
class Library
{
	public static function createParser(config:Config):Parser
	{
		return new Parser(config);
	}

	public static function createConfig():Config
	{
		return new Config();
	}
}
