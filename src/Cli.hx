package;

typedef CommandArguments = {
    var filepath:String;
}

/**
 * The CLI version.
 */
class Cli
{
    public function new()
    {
        var arguments = parseCommandArguments();
        var filepath = arguments.filepath;
        if(!sys.FileSystem.exists(filepath))
        {
            printError('"$filepath" does not exist.');
            return;
        }
        if(sys.FileSystem.isDirectory(filepath))
        {
            printError('"$filepath" is a directory.');
            return;
        }
        var content = sys.io.File.getContent(filepath);

        var parser = new Parser();
        parser.parse(content);
        if(!parser.hasError)
        {
            Sys.println(parser.getResultAsString());
        }
        else
        {
            printError('${parser.errorMessage}');
        }
    }

    public static function printError(message:String):Void
    {
        Sys.stderr().writeString('$message\n');
        Sys.stderr().flush();
    }

    private static function parseCommandArguments():CommandArguments
    {
        var arguments = {
            filepath : ""
        };
        var args = Sys.args();
        if(args.length >= 1)
        {
            arguments.filepath = args[0];
        }
        return arguments;
    }
}
