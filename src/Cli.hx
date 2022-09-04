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
        if(parser.hasError)
        {
            printError('${parser.errorMessage}');
            return;
        }

        if(arguments.config.toJson)
        {
            Sys.println(parser.getResultAsJson());
        }
        else
        {
            Sys.println(parser.getResultAsString());
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
            if(args[i] == "--no-ignored" || args[i] == "-nig")
            {
                arguments.config.displayIgnored = false;
            }
            else if(args[i] == "--no-ignored-and-calculated" || args[i] == "-nic")
            {
                arguments.config.displayIgnoredAndCalculated = false;
            }
            else if(args[i] == "--no-total" || args[i] == "-nt")
            {
                arguments.config.displayTotalNode = false;
            }
            else if(args[i] == "--no-indent" || args[i] == "-nin")
            {
                arguments.config.addIndent = false;
            }
            else if(args[i] == "--prettify" || args[i] == "-p")
            {
                arguments.config.prettify = true;
            }
            else if(args[i] == "--to-json" || args[i] == "-tj")
            {
                arguments.config.toJson = true;
            }
            else if(args[i] == "--total-name" || args[i] == "-tn")
            {
                i++;
                if(i < args.length)
                {
                    arguments.config.totalName = args[i];
                }
                else
                {
                    // TODO: raise error because of missing argument
                }
            }
            else
            {
                if(arguments.filepath == "")
                {
                    arguments.filepath = args[i];
                }
                else
                {
                    // TODO: raise error
                }
            }
            i++;
        }
        return arguments;
    }
}
