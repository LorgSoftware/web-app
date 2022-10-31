package;

typedef ParseNodeResult = {
    var node:Node;
    var currentLineIndex:Int;
}

/**
 * Parse the content and return the results in appropriate format.
 */
class Parser
{
    public final NODE_DEFINITION_CHARACTER:String = "#";
    public final UNIT_DEFINITION_CHARACTER:String = "$";
    public final UNIT_NAME_VALUE_SEPARATOR:String = ":";


    private var totalNode:Node;
    private var existingUnits:Map<String, Bool>;
    private var sortedUnitNames:Array<String>;

    private final config:Config;

    public var hasError:Bool;
    public var errorMessage:String;

    private static final ERROR_UNKNOWN_MESSAGE = "Unknown internal error.";

    private function reset():Void
    {
        totalNode = new Node("TOTAL");
        existingUnits = [];
        sortedUnitNames = [];
        hasError = false;
        errorMessage = "";
    }

    public function new(config:Config)
    {
        this.config = config;
        reset();
    }

    public function parse(content:String):Void
    {
        try
        {
            reset();
            extractTotalNodeFromText(content);
            calculateNodeUnits(totalNode, []);
            for(name in existingUnits.keys())
            {
                sortedUnitNames.push(name);
                sortedUnitNames.sort((a, b) -> (a < b) ? -1 : 1);
            }
        }
        catch(e:Any)
        {
            hasError = true;
            errorMessage = Std.string(e);
        }
    }

    public function getResultAsString():String
    {
        var nodesToConvert:Array<Node> = getNodesToConvert();
        var convert = (config.prettify) ?
            function(node:Node) { return convertNodeToStringPretty(node); } :
            function(node:Node) { return convertNodeToStringSimple(node); };

        var lines:Array<String> = [];
        for(node in getNodesToConvert())
        {
            var nodeLines = convert(node);
            for(line in nodeLines)
            {
                lines.push(line);
            }
        }
        return lines.join("\n");
    }

    public function getResultAsJson():String
    {
        var nodesToConvert:Array<Node> = getNodesToConvert();
        var spaces = (config.prettify) ? "    " : null;
        return haxe.Json.stringify(nodesToConvert, null, spaces);
    }

    private function getNodesToConvert():Array<Node>
    {
        if(config.displayTotalNode)
        {
            return [totalNode];
        }
        else
        {
            return totalNode.children;
        }
    }

    private inline function isWhitespace(c:String):Bool
    {
        return c == " " || c == "\t";
    }

    private inline function isEndOfLine(c:String):Bool
    {
        return c == "\n" || c == "";
    }

    // Move the stream so the next time "get()" is called it returns something
    // else than a white space.
    private function skipWhitespaces(stream:StringStream):Void
    {
        // No need to check EOF because stream returns "" when EOF.
        while(isWhitespace(stream.peek()))
        {
            stream.get();
        }
    }

    private function skipLine(stream:StringStream):Void
    {
        while(!isEndOfLine(stream.peek()))
        {
            stream.get();
        }
    }

    private inline function isDigit(charCode:Int):Bool
    {
        return (48 <= charCode && charCode <= 57);
    }

    // The value should be in the format /[-+]?\d+(\.\d+)?/
    private function isUnitValueOK(value:String):Bool
    {
        if(value.length == 0)
        {
            return false;
        }

        var i:Int = 0;
        // Check if has sign.
        if(value.charAt(0) == '-' || value.charAt(0) == '+')
        {
            i = 1;
        }

        // Check if has only digits or digits then a decimal point for floats.
        while(i < value.length)
        {
            if(isDigit(value.charCodeAt(i)))
            {
                i++;
            }
            else if(value.charAt(i) == '.')
            {
                break;
            }
            else
            {
                return false;
            }
        }

        // Check if this is the definition of an integer.
        if(i == value.length && value.charAt(value.length - 1) != '.')
        {
            return true;
        }

        // Trailing points are not allowed.
        if(i == value.length - 1 && value.charAt(i) == '.')
        {
            return false;
        }

        // Check the decimals of the supposedly float.
        for(j in (i + 1)...value.length)
        {
            if(!isDigit(value.charCodeAt(j)))
            {
               return false;
            }
        }
        return true;
    }

    // `firstChar` is needed because we often detect the need of getting the rest
    // of the line after checking the first character.
    // After this function ran, `stream.get()` returns the first character after
    // the line.
    private function getRestOfLineWithoutTrailingSpaces(
        stream:StringStream, firstChar:String
    )
    {
        var content:String = "";
        var c:String = firstChar;
        var trailingSpaceCount = 0;
        while(!isEndOfLine(c))
        {
            content += c;
            if(isWhitespace(c))
            {
                trailingSpaceCount++;
            }
            else
            {
                trailingSpaceCount = 0;
            }
            c = stream.get();
        }
        if(trailingSpaceCount > 0)
        {
            content = content.substr(0, content.length - trailingSpaceCount);
        }
        return content;
    }

    private function getSubstringWithoutLeadingTrailingSpaces(
        str:String, start:Int, end:Int
    ):String
    {
        var substring = str.substring(start, end);
        return StringTools.trim(substring);
    }

    private function formatError(message:String, line:Int, column:Int=0):String
    {
        var errorMessage:String = 'Line ${line}';
        if(column != 0)
        {
            errorMessage += ', column ${column}';
        }
        errorMessage += ": " + message;
        return errorMessage;
    }

    private inline function throwNodeWithoutTitle(line:Int):Void
    {
        throw formatError(
            "The node has no title.", line
        );
    }

    private inline function throwNodeWithoutDirectParent(line:Int):Void
    {
        throw formatError(
            "The node is not a direct descendant to any other node.", line
        );
    }

    private inline function throwUnitDefinitionIllFormed(line:Int):Void
    {
        var errorMessage:String = formatError(
            "The unit definition is ill-formed.", line
        );
        errorMessage += "\nThe unit defintion should follow this format:";
        errorMessage += "\n    $ UNIT_NAME : UNIT_VALUE";
        throw errorMessage;
    }

    private function extractTotalNodeFromText(content:String):Void
    {
        var stream = new StringStream(content);

        // Contain the node currently being parsed. We use a stack to avoid
        // unnecessary recursion. The stack size represents the level of the node
        // on top. The node below it is its direct parent.
        var nodesToAdd = new Stack<Node>();

        while(!stream.eof())
        {
            // Skip useless possible white spaces at the beginning of the line.
            if(stream.column == 0 && isWhitespace(stream.peek()))
            {
                skipWhitespaces(stream);
                if(stream.eof())
                {
                    break;
                }
            }

            var c = stream.get();

            if(c == NODE_DEFINITION_CHARACTER)
            {
                // Keep the current line because maybe the node definition is
                // ill-formed, and when we detect it the stream is pointing to the
                // next line.
                var currentLine:Int = stream.line;

                // Get node level.
                var level:Int = 0;
                while(c == NODE_DEFINITION_CHARACTER)
                {
                    level++;
                    c = stream.get();
                }

                // Get node title.
                if(isWhitespace(c))
                {
                    skipWhitespaces(stream);
                }
                c = stream.get();
                if(isEndOfLine(c))
                {
                    throwNodeWithoutTitle(currentLine);
                }
                var title:String = getRestOfLineWithoutTrailingSpaces(stream, c);

                // Manage hierarchy.
                if(level > nodesToAdd.length + 1)
                {
                    throwNodeWithoutDirectParent(currentLine);
                }
                while(level < nodesToAdd.length + 1)
                {
                    // Moving the siblings and nephews until the top of the stack
                    // is the direct parent of the current node.
                    var other:Node = nodesToAdd.top;
                    nodesToAdd.pop();
                    if(nodesToAdd.length > 0)
                    {
                        nodesToAdd.top.children.push(other);
                    }
                    else
                    {
                        totalNode.children.push(other);
                    }
                }
                var currentNode = new Node(title);
                nodesToAdd.push(currentNode);
            }
            else if(c == UNIT_DEFINITION_CHARACTER)
            {
                // Keep the current line because maybe the node definition is
                // ill-formed, and when we detect it the stream is pointing to the
                // next line.
                var currentLine:Int = stream.line;

                // We get all the line immediately because unit names can contain
                // `UNIT_NAME_VALUE_SEPARATOR`.
                skipWhitespaces(stream);
                var definition:String = getRestOfLineWithoutTrailingSpaces(stream, stream.get());
                if(definition.length == 0)
                {
                    throwUnitDefinitionIllFormed(currentLine);
                }

                // We get the last `UNIT_NAME_VALUE_SEPARATOR` index so it is sure
                // that everything before it is part of the unit name.
                var separatorIndex = definition.length - 1;
                {
                    while(separatorIndex > 0)
                    {
                        if(definition.charAt(separatorIndex) == UNIT_NAME_VALUE_SEPARATOR)
                        {
                            break;
                        }
                        separatorIndex--;
                    }
                    if(definition.charAt(separatorIndex) != UNIT_NAME_VALUE_SEPARATOR)
                    {
                        throwUnitDefinitionIllFormed(currentLine);
                    }
                }
                // The only thing in the node definition is `UNIT_DEFINITION_CHARACTER`
                if(definition.length == 1)
                {
                        throwUnitDefinitionIllFormed(currentLine);
                }

                // Get name.
                var name:String = getSubstringWithoutLeadingTrailingSpaces(
                    definition, 0, separatorIndex
                );
                if(name.length == 0)
                {
                    throwUnitDefinitionIllFormed(currentLine);
                }


                // Get value.
                var valueString = getSubstringWithoutLeadingTrailingSpaces(
                    definition, separatorIndex + 1, definition.length
                );
                if(valueString.length == 0)
                {
                    throwUnitDefinitionIllFormed(currentLine);
                }
                if(!isUnitValueOK(valueString))
                {
                    throwUnitDefinitionIllFormed(currentLine);
                }

                // Check the unit definition is not outside of a node. We prefer to
                // do that after checking the syntax of the unit definition.
                if(nodesToAdd.empty())
                {
                    throwUnitDefinitionIllFormed(currentLine);
                }

                var unit = new Unit(name, Std.parseFloat(valueString), true);
                nodesToAdd.top.units[name] = unit;
                existingUnits[name] = true;
            }
            else if(c == "\n")
            {
                continue;
            }
            else
            {
                skipLine(stream);
            }
        }

        if(!nodesToAdd.empty())
        {
            while(nodesToAdd.length > 1)
            {
                var other:Node = nodesToAdd.top;
                nodesToAdd.pop();
                nodesToAdd.top.children.push(other);
            }
            totalNode.children.push(nodesToAdd.top);
            nodesToAdd.pop();
        }
    }

    private function calculateNodeUnits(node:Node, ignoredUnits:Map<String, Bool>):Void
    {
        // Update node units list
        var calculatedUnitNames = new Array<String>();  // No need to check real units
        for(name in existingUnits.keys())
        {
            if(!node.units.exists(name))
            {
                node.units[name] = new Unit(name, 0, false);
                calculatedUnitNames.push(name);
            }
        }

        for(name in ignoredUnits.keys())
        {
            node.units[name].isIgnored = true;
        }

        if(node.children.length == 0)
        {
            return;
        }

        var childrenUnitsToIgnore:Map<String, Bool> = [];
        for(name in node.units.keys())
        {
            if(node.units[name].isReal || node.units[name].isIgnored)
            {
                childrenUnitsToIgnore[name] = true;
            }
        }

        for(child in node.children)
        {
            calculateNodeUnits(child, childrenUnitsToIgnore);
            for(name in calculatedUnitNames)
            {
                node.units[name].value += child.units[name].value;
            }
        }
    }

    private inline function unitToString(unit:Unit):String
    {
        var str = '$ ${unit.name}: ${unit.value}';
        if(!unit.isReal)
        {
            str += ' [Calculated]';
        }
        if(unit.isIgnored)
        {
            str += ' [Ignored]';
        }
        return str;
    }

    private function convertNodeToStringSimple(
        node:Node, indentLevel=0
    ):Array<String>
    {
        var lines:Array<String> = [];

        var heading = "#";
        var indent = "";
        for(i in 0...indentLevel)
        {
            heading += "#";
            indent += "  ";
        }
        lines.push('${indent}${heading} ${node.title}');

        for(name in sortedUnitNames)
        {
            var unitStr = unitToString(node.units[name]);
            lines.push('${indent}  ${unitStr}');
        }

        for(i in 0...node.children.length)
        {
            var child = node.children[i];
            var childLines = convertNodeToStringSimple(child, indentLevel + 1);
            for(line in childLines)
            {
                lines.push(line);
            }
        }

        return lines;
    }

    private function convertNodeToStringPretty(
        node:Node, indentLevel:Int=0, prefixFromParent="",
        hasNextSibling:Bool=false
    ):Array<String>
    {
        var lines:Array<String> = [];

        if(indentLevel == 0)
        {
            lines.push('${node.title}');
        }
        else
        {
            if(hasNextSibling)
            {
                lines.push('${prefixFromParent}├── ${node.title}');
            }
            else
            {
                lines.push('${prefixFromParent}└── ${node.title}');
            }
        }

        var prefixForNextLines:String = "";
        {
            if(indentLevel == 0)
            {
                prefixForNextLines = "";
            }
            else
            {
                var toAdd = hasNextSibling ? "│   " : "    ";
                prefixForNextLines = prefixFromParent + toAdd;
            }
        };

        for(name in sortedUnitNames)
        {
            var unitStr = unitToString(node.units[name]);
            if(node.children.length != 0)
            {
                lines.push('${prefixForNextLines}│ ${unitStr}');
            }
            else
            {
                lines.push('${prefixForNextLines}  ${unitStr}');
            }
        }

        for(i in 0...node.children.length)
        {
            var child = node.children[i];
            var childHasNextSibling = (i < node.children.length - 1);
            var childLines = convertNodeToStringPretty(
                child, indentLevel + 1, prefixForNextLines, childHasNextSibling
            );

            for(line in childLines)
            {
                lines.push(line);
            }
        }

        return lines;
    }
}
