package;

/**
 * The default configuration.
 */
@:expose("Lorg.Config")
@:keep
class Config
{
    public var printVersion:Bool = false;
    public var displayTotalNode:Bool = false;
    public var prettify:Bool = false;
    public var toJson:Bool = false;

    public function new()
    {
    }
}
