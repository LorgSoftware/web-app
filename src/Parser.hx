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
        var lines = convertNodeToString(totalNode);
        return lines.join("\n");
    }

    private function extractTotalNodeFromText(content:String):Void
    {
        var lines = content.split("\n");
        var i = 0;
        while(i < lines.length)
        {
            if(isNodeDefinition(lines[i]))
            {
                var result = parseNode(lines, i);
                i = result.currentLineIndex;
                totalNode.children.push(result.node);
            }
            else
            {
                i++;
            }
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
            if(node.units[name].isReal)
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

    private function convertNodeToString(node:Node, indentLevel:Int=0):Array<String>
    {
        var indent = "";
        for(i in 0...indentLevel)
        {
            indent += "  ";
        }

        var lines = ['${indent}# ${node.title}'];

        for(name in sortedUnitNames)
        {
            var value = node.units[name].value;
            var isIgnored = node.units[name].isIgnored;
            var isReal = node.units[name].isReal;

            if(isIgnored && !config.displayIgnored)
            {
                continue;
            }

            var toDisplay = '${indent}  ¤ ${name}: ${value}';
            if(!isReal)
            {
                toDisplay += ' [Calculated]';
            }
            if(isIgnored)
            {
                toDisplay += ' [Ignored]';
            }
            lines.push(toDisplay);
        }

        for(child in node.children)
        {
            var childLines = convertNodeToString(child, indentLevel + 1);
            for(line in childLines)
            {
                lines.push(line);
            }
        }

        return lines;
    }

    private function parseNode(lines:Array<String>, i:Int):ParseNodeResult
    {
        if(i >= lines.length)
        {
            throw ERROR_UNKNOWN_MESSAGE;
        }

        if(!isNodeDefinition(lines[i]))
        {
            throw ERROR_UNKNOWN_MESSAGE;
        }

        var node = new Node(getNodeTitle(lines[i]));
        var currentLevel = countNodeLevel(lines[i]);

        var currentLineIndex = i + 1;

        while(currentLineIndex < lines.length)
        {
            var currentLine = lines[currentLineIndex];
            if(isNodeDefinition(currentLine))
            {
                // Child node if the level is higher than current one.
                var newNodeLevel = countNodeLevel(currentLine);
                if(newNodeLevel > currentLevel)
                {
                    if(newNodeLevel > currentLevel + 1)
                    {
                        throw 'Line ${currentLineIndex + 1}: Expected node of level ${currentLevel + 1} but got one of level ${newNodeLevel}.';
                    }
                    var childResult = parseNode(lines, currentLineIndex);
                    node.children.push(childResult.node);
                    currentLineIndex = childResult.currentLineIndex;
                }
                else
                {
                    return {
                        node : node,
                        currentLineIndex : currentLineIndex,
                    };
                }
            }
            else
            {
                if(isUnitDefinition(currentLine))
                {
                    try
                    {
                        var unit = parseUnit(currentLine);
                        node.units[unit.name] = unit;
                    }
                    catch(e:Any)
                    {
                        throw 'Line ${currentLineIndex + 1}: ${e}';
                    }
                }

                currentLineIndex++;
            }
        }

        return {
            node : node,
            currentLineIndex : currentLineIndex,
        };
    }

    private function parseUnit(line:String):Unit
    {
        var name = getUnitName(line);
        var value = getUnitValue(line);
        if(!existingUnits.exists(name))
        {
            existingUnits[name] = true;
        }
        return new Unit(name, value);
    }

    private function getNodeDefinitionRegex():EReg
    {
        return ~/^\s*(#+)\s*(.+)/;
    }

    private function isNodeDefinition(line:String):Bool
    {
        return getNodeDefinitionRegex().match(line);
    }

    private function countNodeLevel(line:String):Int
    {
        var r = getNodeDefinitionRegex();
        if(!r.match(line))
        {
            return 0;
        }
        return r.matched(1).length;
    }

    private function getNodeTitle(line:String):String
    {
        var r = getNodeDefinitionRegex();
        if(!r.match(line))
        {
            return "";
        }
        return r.matched(2);
    }

    private function getUnitDefinitionRegex():EReg
    {
        // TODO: change the unit value regex?
        return ~/^\s*¤\s*(.+)\s*:\s*(.+)/;
    }

    private function isUnitDefinition(line:String):Bool
    {
        return getUnitDefinitionRegex().match(line);
    }

    private function getUnitName(line:String):String
    {
        var r = getUnitDefinitionRegex();
        if(!r.match(line))
        {
            return "";
        }
        return r.matched(1);
    }

    private function getUnitValue(line:String):Float
    {
        var r = getUnitDefinitionRegex();
        if(!r.match(line))
        {
            return 0;
        }
        var valueString = r.matched(2);
        try
        {
            var value = Std.parseFloat(valueString);
            return value;
        }
        catch(e:Any)
        {
            throw 'Cannot convert value "${valueString}".';
        }
    }
}
