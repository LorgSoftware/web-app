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
    public static final EXIT_ERROR_ARGUMENTS:Int = 1;
    public static final EXIT_ERROR_PARSER:Int = 2;

    public function new()
    {
        var arguments = parseCommandArguments();
        var filepath = arguments.filepath;
        if(!sys.FileSystem.exists(filepath))
        {
            printError('"$filepath" does not exist.');
            Sys.exit(EXIT_ERROR_ARGUMENTS);
        }
        if(sys.FileSystem.isDirectory(filepath))
        {
            printError('"$filepath" is a directory.');
            Sys.exit(EXIT_ERROR_ARGUMENTS);
        }
        var content = sys.io.File.getContent(filepath);

        var parser = new Parser(arguments.config);
        parser.parse(content);
        if(parser.hasError)
        {
            printError('${parser.errorMessage}');
            return;
            Sys.exit(EXIT_ERROR_PARSER);
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
            if(args[i].length > 1 && args[i].charAt(0) == "-" && args[i].charAt(1) != "-")
            {
                for(j in 1...args[i].length)
                {
                    var c = args[i].charAt(j);
                    if(args[i] == "v")
                    {
                        arguments.config.printVersion = true;
                    }
                    else if(args[i] == "t")
                    {
                        arguments.config.displayTotalNode = true;
                    }
                    else if(args[i] == "p")
                    {
                        arguments.config.prettify = true;
                    }
                    else if(args[i] == "j")
                    {
                        arguments.config.toJson = true;
                    }

                }
            }
            else if(args[i] == "--version" || args[i] == "-v")
            {
                arguments.config.printVersion = true;
            }
            else if(args[i] == "--total" || args[i] == "-t")
            {
                arguments.config.displayTotalNode = true;
            }
            else if(args[i] == "--prettify" || args[i] == "-p")
            {
                arguments.config.prettify = true;
            }
            else if(args[i] == "--json" || args[i] == "-j")
            {
                arguments.config.toJson = true;
            }
            else
            {
                if(arguments.filepath == "")
                {
                    arguments.filepath = args[i];
                }
                else
                {
                    printError('Only one file at a time can be parsed.');
                    Sys.exit(EXIT_ERROR_ARGUMENTS);
                }
            }
            i++;
        }
        return arguments;
    }
}
