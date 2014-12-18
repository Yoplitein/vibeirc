/++
    Macros:
        SYMBOL_LINK = $(LINK2 #$1, $1)
        DDOC = <!DOCTYPE html>
        <html lang="en">
        <head>
            <title>$(TITLE)</title>
            <meta charset="utf-8" />
            <style type="text/css">
                table, tr, td
                {
                    /* putting these on their own line caused most of the document to be left out (dmd bug?) */
                    border-collapse: collapse; border: 1px solid black; padding: 5px;
                }
            </style>
        </head>
        <body>
            <h1>$(TITLE)</h1>
            $(BODY)
        </body>
        </html>
+/
module vibeirc;

private
{
    import std.string: split;
}

private enum CTCP_ENCAPSULATOR = '\x01';

/++
    A struct containing details about a connection.
+/
struct ConnectionParameters
{
    string hostname; ///The _hostname or address of the IRC server.
    ushort port; ///The _port of the server.
    string password = null; ///The _password for the server, if any.
    string username = "vibeIRC"; ///The _username, later used by the server in this connection's hostmask.
    string realname = null; ///The _realname as returned by the WHOIS command.
}

/++
    A struct containing details about a user.
+/
struct User
{
    string nickname; ///The _nickname of this user.
    string username; ///The _username portion of this user's hostmask.
    string hostname; ///The _hostname portion of this user's hostmask.
}

/++
    A struct containing details about an incoming message.
+/
struct Message
{
    User sender; ///The user who sent the message.
    string receiver; ///The destination of the message, either a user or a channel.
    string ctcpCommand; ///The CTCP command, if any.
    string message; ///The _message body.
    
    /++
        Returns whether this message uses CTCP.
    +/
    @property bool isCTCP()
    {
        return ctcpCommand != null;
    }
}

//Thrown from line_received, handle_numeric or handle_command in case of an error
private class GracelessDisconnect: Exception
{
    this(string msg)
    {
        super(msg);
    }
}

/++
    The base class for IRC connections.
+/
class IRCConnection
{
    import vibe.core.net: TCPConnection;
    import vibe.core.log: logDebug, logError, logInfo; //FIXME: logInfo
    
    ConnectionParameters connectionParameters; ///The connection parameters passed to $(SYMBOL_LINK irc_connect).
    TCPConnection transport; ///The vibe socket underlying this connection.
    private string _nickname;
    
    /++
        Default constructor. Should not be called from user code.
        
        See_Also:
            $(SYMBOL_LINK irc_connect)
    +/
    protected this() {}
    
    private void protocol_loop()
    in { assert(transport && transport.connected); }
    body
    {
        import vibe.stream.operations: readLine;
        
        string disconnectReason = "Connection terminated gracefully";
        
        logDebug("irc connected");
        
        if(connectionParameters.password != null)
            send_line("PASS %s", connectionParameters.password);
        
        send_line("NICK %s", nickname);
        send_line("USER %s 0 * :%s", connectionParameters.username, connectionParameters.realname);
        
        while(transport.connected)
        {
            string line;
            
            try
                line = cast(string)transport.readLine;
            catch(Exception err)
            {
                logError(err.toString);
                
                break;
            }
            
            version(IrcDebugLogging) logDebug("irc recv: %s", line);
            
            try
                line_received(line);
            catch(GracelessDisconnect err)
            {
                disconnectReason = err.msg;
                
                transport.close;
            }
        }
        
        disconnected(disconnectReason);
        logDebug("irc disconnected");
    }
    
    private void line_received(string line)
    {
        import std.conv: ConvException, to;
        
        string[] parts = line.split(" ");
        
        switch(parts[0])
        {
            case "PING":
                send_line("PONG %s", parts[1]);
                
                break;
            case "ERROR":
                throw new GracelessDisconnect(parts.drop_first.join.drop_first);
            default:
                parts[0] = parts[0].drop_first;
                
                try
                    handle_numeric(parts[0], parts[1].to!int, parts[2 .. $]);
                catch(ConvException err)
                    handle_command(parts[0], parts[1], parts[2 .. $]);
        }
    }
    
    private void handle_command(string prefix, string command, string[] parts)
    {
        logDebug("handle_command(%s, %s, %s)", prefix, command, parts);
        
        switch(command)
        {
            case "NOTICE":
            case "PRIVMSG":
                Message msg;
                string message = parts.drop_first.join;
                msg.sender = prefix.split_userinfo;
                msg.receiver = parts[0];
                msg.message = message != null ? message.drop_first : "";
                
                if(message.is_ctcp)
                {
                    auto parsedCtcp = message.parse_ctcp;
                    msg.ctcpCommand = parsedCtcp.command;
                    msg.message = parsedCtcp.message;
                }
                
                if(command == "NOTICE")
                    notice(msg);
                else
                    privmsg(msg);
                
                break;
            case "JOIN":
                user_joined(prefix.split_userinfo, parts[0].drop_first);
                
                break;
            case "PART":
                user_left(prefix.split_userinfo, parts[0], parts.drop_first.join.drop_first);
                
                break;
            case "QUIT":
                user_quit(prefix.split_userinfo, parts.join.drop_first);
                
                break;
            case "NICK":
                user_renamed(prefix.split_userinfo, parts[0].drop_first);
                
                break;
            case "KICK":
                user_kicked(prefix.split_userinfo, parts[1], parts[0], parts[2 .. $].join.drop_first);
                
                break;
            default:
                unknown_command(prefix, command, parts);
        }
    }
    
    private void handle_numeric(string prefix, int id, string[] parts)
    {
        logDebug("handle_numeric(%s, %s, %s)", prefix, id, parts);
        
        switch(id)
        {
            case 1: //RPL_WELCOME (connection success)
                signed_on;
                
                break;
            case 432: //ERR_ERRONEUSNICKNAME
                throw new GracelessDisconnect("Erroneus nickname"); //TODO: handle gracefully?
            case 433: //ERR_NICKNAMEINUSE
                throw new GracelessDisconnect("Nickname already in use"); //TODO: handle gracefully?
            default:
                unknown_numeric(prefix, id, parts);
        }
    }
    
    /++
        Get this connection's _nickname.
    +/
    final @property string nickname()
    {
        return _nickname;
    }
    
    /++
        Set this connection's _nickname.
    +/
    final @property string nickname(string newNick)
    {
        if(transport && transport.connected)
            send_line("NICK %s", newNick);
        
        return _nickname = newNick;
    }
    
    final void connect()
    in { assert(transport is null ? true : !transport.connected); }
    body
    {
        import vibe.core.net: connectTCP;
        import vibe.core.core: runTask;
        
        transport = connectTCP(connectionParameters.hostname, connectionParameters.port);
        
        runTask(&protocol_loop);
    }
    
    final void disconnect(string reason)
    in { assert(transport && transport.connected); }
    body
    {
        send_line("QUIT :%s", reason);
        
        transport.close;
    }
    
    /++
        Send a formatted line.
        
        Params:
            contents = format string for the line
            args = formatting arguments
    +/
    final void send_line(Args...)(string contents, Args args)
    in { assert(transport && transport.connected); }
    body
    {
        import std.string: format;
        
        //TODO: buffering
        contents = contents.format(args);
        
        version(IrcDebugLogging) logDebug("irc send: %s", contents);
        transport.write(contents ~ "\r\n");
    }
    
    /++
        Send a _message.
        
        Params:
            destination = _destination of the message, either a #channel or a nickname
            notice = send a NOTICE instead of a PRIVMSG
    +/
    final void send_message(string destination, string message, bool notice = false)
    {
        send_line("%s %s :%s", notice ? "NOTICE" : "PRIVMSG", destination, message);
    }
    
    /++
        Join a channel.
    +/
    final void join_channel(string name)
    {
        send_line("JOIN %s", name);
    }
    
    /++
        Called when an unknown command is received.
        
        Params:
            prefix = origin of the _command, either a server or a user
            command = the name of the _command
            arguments = the body of the _command
    +/
    void unknown_command(string prefix, string command, string[] arguments) {}
    
    /++
        Called when an unknown numeric command is received.
        
        Params:
            prefix = origin of the command, either a server or a user
            id = the number of the command
            arguments = the body of the command
    +/
    void unknown_numeric(string prefix, int id, string[] arguments) {}
    
    /++
        Called after succesfully logging in to the network.
    +/
    void signed_on() {}
    
    /++
        Called after being _disconnected from the network.
    +/
    void disconnected(string reason) {}
    
    /++
        Called upon reception of an incoming private message.
    +/
    void privmsg(Message message) {}
    
    /++
        Called upon reception of an incoming _notice.
        
        A _notice is similar to a privmsg, except it is expected to not generate automatic replies.
    +/
    void notice(Message message) {}
    
    /++
        Called when a _user joins a _channel.
    +/
    void user_joined(User user, string channel) {}
    
    /++
        Called when a _user leaves a _channel.
    +/
    void user_left(User user, string channel, string reason) {}
    
    /++
        Called when a _user disconnects from the network.
    +/
    void user_quit(User user, string reason) {}
    
    /++
        Called when a _user is kicked from a _channel.
        
        Params:
            kicker = the _user that performed the kick
            user = the _user that was kicked
    +/
    void user_kicked(User kicker, string user, string channel, string reason) {}
    
    /++
        Called when a _user changes their nickname.
    +/
    void user_renamed(User user, string oldNick) {}
}

/++
    Establish a connection to a network and construct an instance of ConnectionClass
    to handle events from that connection.
+/
ConnectionClass irc_connect(ConnectionClass)(ConnectionParameters parameters)
if(is(ConnectionClass: IRCConnection))
{
    auto connection = new ConnectionClass;
    connection.connectionParameters = parameters;
    
    connection.connect;
    
    return connection;
}

private User split_userinfo(string info)
{
    import std.regex: ctRegex, matchFirst;
    
    auto expression = ctRegex!(r"^(.+)!(.+)@(.+)$");
    auto matches = info.matchFirst(expression);
    
    if(matches.empty)
        throw new Exception("Invalid userinfo: " ~ info);
    
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

private bool is_ctcp(string message)
{
    return message[0] == CTCP_ENCAPSULATOR && message[$ - 1] == CTCP_ENCAPSULATOR;
}

private auto parse_ctcp(string message)
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

private Array drop_first(Array)(Array array)
{
    return array[1 .. $];
}

private auto join(Array)(Array array)
{
    static import std.string;
    
    return std.string.join(array, " ");
}
