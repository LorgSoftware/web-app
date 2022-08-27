package;

typedef CommandArguments = {
    var filepath:String;
    var config:Config;
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

        var parser = new Parser(arguments.config);
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
            filepath : "",
            config : new Config(),
        };
        var args = Sys.args();
        var i = 0;
        while(i < args.length)
        {
            if(args[i] == "--no-ignored")
            {
                arguments.config.displayIgnored = false;
            }
            else
            {
                arguments.filepath = args[i];
                break;
            }
            i++;
        }
        return arguments;
    }
}
