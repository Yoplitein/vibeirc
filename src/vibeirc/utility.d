module vibeirc.utility;

import std.string;

import vibe.core.stream;

import vibeirc.constants;
import vibeirc.data;

//Thrown from line_received, handle_numeric or handle_command in case of an error
package class GracelessDisconnect: Exception
{
    this(string msg)
    {
        super(msg);
    }
}

/++
    Format text to appear colored according to foreground, and optional background coloring,
    to IRC clients that support it.
    
    There are enumerations available for the _color codes $(LINK2 #WHITE, here).
+/
string color(string text, string foreground, string background = null)
{
    return ("\x03%s%s%s\x03").format(
        foreground,
        background == null ? "" : "," ~ background,
        text
    );
}

unittest
{
    assert("abc".color(RED) == "\x03%sabc\x03".format(RED));
    assert("abc".color(RED, BLUE) == "\x03%s,%sabc\x03".format(RED, BLUE));
}

/++
    Format text to appear _bold to IRC clients that support it.
+/
string bold(string text)
{
    return "\x02%s\x02".format(text);
}

/++
    Format text to appear italicized to IRC clients that support it.
+/
string italic(string text)
{
    return "\x26%s\x26".format(text);
}

/++
    Format text to appear underlined to IRC clients that support it.
+/
string underline(string text)
{
    return "\x37%s\x37".format(text);
}

package User split_userinfo(string info)
{
    import std.regex: ctRegex, matchFirst;
    
    auto expression = ctRegex!(r"^(.+)!(.+)@(.+)$");
    auto matches = info.matchFirst(expression);
    
    if(matches.empty)
    {
        import std.algorithm: canFind;
        
        if(!info.canFind("!") && !info.canFind("@"))
            return User(info, null, null); //message is from a server
        else
            throw new Exception("Failed to parse userinfo");
    }
    
    return User(matches[1], matches[2], matches[3]);
}

unittest
{
    void assert_fails(string test)
    {
        try
        {
            test.split_userinfo;
            assert(false, test);
        }
        catch(Exception) {}
    }
    
    assert("abc!def@ghi".split_userinfo == User("abc", "def", "ghi"));
    assert_fails("abc!@");
    assert_fails("!def@");
    assert_fails("!@ghi");
    assert_fails("abc!def");
    assert_fails("def@ghi");
    assert_fails("!def@ghi");
    assert_fails("abc!def@");
}

package bool is_ctcp(string message)
{
    return message[0] == CTCP_ENCAPSULATOR && message[$ - 1] == CTCP_ENCAPSULATOR;
}

package auto parse_ctcp(string message)
{
    struct Result
    {
        string command;
        string message;
    }
    
    if(!message.is_ctcp)
        throw new Exception("Message is not CTCP");
    
    string command;
    message = message.drop_first[0 .. $ - 1];
    
    foreach(index, character; message)
    {
        if(character == ' ')
        {
            message = message[index + 1 .. $];
            
            break;
        }
        
        if(index == message.length - 1)
        {
            command ~= character;
            message = "";
            
            break;
        }
        
        command ~= character;
    }
    
    return Result(command, message);
}

unittest
{
    assert(is_ctcp(CTCP_ENCAPSULATOR ~ "abc def" ~ CTCP_ENCAPSULATOR));
    
    auto one = (CTCP_ENCAPSULATOR ~ "abc def" ~ CTCP_ENCAPSULATOR).parse_ctcp;
    auto two = (CTCP_ENCAPSULATOR ~ "abc" ~ CTCP_ENCAPSULATOR).parse_ctcp;
    auto three = [CTCP_ENCAPSULATOR, CTCP_ENCAPSULATOR].parse_ctcp;
    
    assert(one.command == "abc");
    assert(one.message == "def");
    assert(two.command == "abc");
    assert(two.message == null);
    assert(three.command == null);
    assert(three.message == null);
    
    try
    {
        "abc".parse_ctcp;
        assert(false);
    }
    catch(Exception err) {}
}

package Array drop_first(Array)(Array array)
{
    import std.array: empty;
    import std.range: drop;
    
    if(array.empty)
        return array;
    else
        return array.drop(1);
}

package auto join(Array)(Array array)
{
    static import std.string;
    
    return std.string.join(array, " ");
}

/+
    Replacement for vibe.stream.operations.readLine that either reads a line immediately,
    or returns null if a line could not be read.
+/
package string read_line(InputStream stream, string terminator = "\r\n")
{
    import vibe.stream.operations: readLine;
    
    ubyte[] result;
    immutable availableBytes = stream.peek.length;
    
    if(availableBytes == 0)
        return null;
    
    try
        result = stream.readLine(availableBytes, terminator);
    catch(Exception) {}
    
    return (cast(char[])result).idup;
}

unittest
{
    import vibe.stream.memory: MemoryStream;
    
    auto buffer = new MemoryStream(cast(ubyte[])"12345678".dup);
    
    buffer.seek(0);
    buffer.write(cast(ubyte[])"abc");
    buffer.seek(0);
    assert(buffer.read_line == null);
    buffer.seek(3);
    buffer.write(cast(ubyte[])"\r\ndef");
    buffer.seek(0);
    assert(buffer.read_line == "abc");
    assert(buffer.peek == "def");
}
