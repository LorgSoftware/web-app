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
        var nodesToConvert:Array<Node> = [];
        if(config.displayTotalNode)
        {
            nodesToConvert.push(totalNode);
        }
        else
        {
            for(node in totalNode.children)
            {
                nodesToConvert.push(node);
            }
        }

        var lines:Array<String> = [];
        for(node in nodesToConvert)
        {
            var nodeLines:Array<String>;
            if(config.prettify)
            {
                nodeLines = convertNodeToStringPretty(node);
            }
            else
            {
                nodeLines = convertNodeToStringSimple(node);
            }
            for(line in nodeLines)
            {
                lines.push(line);
            }
        }
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

    private inline function shouldHideUnit(unit:Unit):Bool
    {
        return (
            (unit.isIgnored && !config.displayIgnored)  ||
            (unit.isIgnored && !unit.isReal && !config.displayIgnoredAndCalculated)
        );
    }

    private inline function unitToString(unit:Unit):String
    {
        var str = '¤ ${unit.name}: ${unit.value}';
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
            if(shouldHideUnit(node.units[name]))
            {
                continue;
            }
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
            if(shouldHideUnit(node.units[name]))
            {
                continue;
            }

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
