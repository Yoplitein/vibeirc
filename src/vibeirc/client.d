///
module vibeirc.client;

import std.datetime;
import std.traits;

import vibe.core.log;
import vibe.core.net;
import vibe.core.task;

import vibeirc.constants;
import vibeirc.data;
import vibeirc.utility;

//Thrown from lineReceived, handleNumeric or handleCommand in case of an error
private class GracelessDisconnect: Exception
{
    this(string msg)
    {
        super(msg);
    }
}

/++
    Represents a connection to an IRC server.
+/
final class IRCClient
{
    private Task protocolTask; //The task running protocolLoop
    private TCPConnection transport; //The TCP socket
    private string[] buffer; //Buffered messages
    private uint bufferSent = 0; //Number of messages sent this time period
    private SysTime bufferNextTime; //The start of the next time period
    
    ///
    this()
    {
        bufferNextTime = SysTime(0L);
    }
    
    /*======================================*
     *======================================*
     *              Properties              *
     *======================================*
     *======================================*/
    
    private string _nickname;
    
    /++
        The display name this client will use.
    +/
    @property string nickname()
    {
        return _nickname;
    }
    
    /++
        ditto
    +/
    @property string nickname(string newNick)
    {
        if(transport && transport.connected)
            sendLine("NICK %s", newNick);
        
        return _nickname = newNick;
    }
    
    private string _username;
    
    /++
        The username shown by the WHOIS command.
    +/
    @property string username()
    {
        return _username;
    }
    
    /++
        ditto
    +/
    @property string username(string newValue)
    {
        return _username = newValue;
    }
    
    private string _realname;
    
    /++
        The real name shown by the WHOIS command.
    +/
    @property string realname()
    {
        return _realname;
    }
    
    /++
        ditto
    +/
    @property string realname(string newValue)
    {
        return _realname = newValue;
    }
    
    private Duration _sleepTimeout = dur!"msecs"(10);
    
    /++
        How long the protocol loop should sleep after failing to read a line.
        
        Defaults to 10 ms.
    +/
    @property Duration sleepTimeout()
    {
        return _sleepTimeout;
    }
    
    /++
        ditto
    +/
    @property Duration sleepTimeout(Duration newValue)
    {
        return _sleepTimeout = newValue;
    }
    
    private bool _buffering = false;
    
    /++
        Whether to buffer outgoing messages.
        
        Defaults to off (false).
    +/
    @property bool buffering()
    {
        return _buffering;
    }
    
    /++
        ditto
    +/
    @property bool buffering(bool newValue)
    {
        return _buffering = newValue;
    }
    
    private uint _bufferLimit = 20;
    
    /++
        Maximum number of messages to send per time period, if buffering is enabled.
        
        Defaults to 20.
    +/
    @property uint bufferLimit()
    {
        return _bufferLimit;
    }
    
    /++
        ditto
    +/
    @property uint bufferLimit(uint newValue)
    {
        return _bufferLimit = newValue;
    }
    
    private Duration _bufferTimeout = dur!"seconds"(30);
    
    /++
        Amount of time to wait before sending each batch of messages, if buffering is enabled.
    +/
    @property Duration bufferTimeout()
    {
        return _bufferTimeout;
    }
    
    /++
        ditto
    +/
    @property Duration bufferTimeout(Duration newValue)
    {
        return _bufferTimeout = newValue;
    }
    
    /*======================================*
     *======================================*
     *              Callbacks               *
     *======================================*
     *======================================*/
    
    private void delegate(string prefix, string command, string[] arguments) _onUnknownCommand;
    
    /++
        Called when an unknown command is received.
        
        Params:
            a = origin of the command, either a server or a user
            b = the name of the command
            c = the body of the command
    +/
    @property typeof(_onUnknownCommand) onUnknownCommand()
    {
        return _onUnknownCommand;
    }
    
    /++
        ditto
    +/
    @property typeof(_onUnknownCommand) onUnknownCommand(typeof(_onUnknownCommand) newValue)
    {
        return _onUnknownCommand = newValue;
    }
    
    private void delegate(string prefix, int id, string[] arguments) _onUnknownNumeric;
    
    /++
        Called when an unknown numeric command is received.
        
        Params:
            a = origin of the command, either a server or a user
            b = the number of the command
            c = the body of the command
    +/
    @property typeof(_onUnknownNumeric) onUnknownNumeric()
    {
        return _onUnknownNumeric;
    }
    
    /++
        ditto
    +/
    @property typeof(_onUnknownNumeric) onUnknownNumeric(typeof(_onUnknownNumeric) newValue)
    {
        return _onUnknownNumeric = newValue;
    }
    
    private bool delegate() _onConnect;
    
    /++
        Called after the connection is established, before logging in to the network.
        
        Returns:
            whether to perform default login procedure
            (send PASSWORD, NICK and USER commands)
    +/
    @property typeof(_onConnect) onConnect()
    {
        return _onConnect;
    }
    
    /++
        ditto
    +/
    @property typeof(_onConnect) onConnect(typeof(_onConnect) newValue)
    {
        return _onConnect = newValue;
    }
    
    private void delegate(string reason) _onDisconnect;
    
    /++
        Called after being disconnected from the network.
        
        Params:
            a = the reason for quitting
    +/
    @property typeof(_onDisconnect) onDisconnect()
    {
        return _onDisconnect;
    }
    
    /++
        ditto
    +/
    @property typeof(_onDisconnect) onDisconnect(typeof(_onDisconnect) newValue)
    {
        return _onDisconnect = newValue;
    }
    
    private void delegate() _onLogin;
    
    /++
        Called after succesfully logging in to the network.
    +/
    @property typeof(_onLogin) onLogin()
    {
        return _onLogin;
    }
    
    /++
        ditto
    +/
    @property typeof(_onLogin) onLogin(typeof(_onLogin) newValue)
    {
        return _onLogin = newValue;
    }
    
    private void delegate(Message message) _onMessage;
    
    /++
        Called upon reception of an incoming message.
        
        Params:
            a = information on the incoming message
    +/
    @property typeof(_onMessage) onMessage()
    {
        return _onMessage;
    }
    
    /++
        ditto
    +/
    @property typeof(_onMessage) onMessage(typeof(_onMessage) newValue)
    {
        return _onMessage = newValue;
    }
    
    private void delegate(Message message) _onNotice;
    
    /++
        Called upon reception of an incoming notice.
        
        A notice is similar to a privmsg, except it is expected to not generate automatic replies.
        
        Params:
            a = information on the incoming message
    +/
    @property typeof(_onNotice) onNotice()
    {
        return _onNotice;
    }
    
    /++
        ditto
    +/
    @property typeof(_onNotice) onNotice(typeof(_onNotice) newValue)
    {
        return _onNotice = newValue;
    }
    
    private void delegate(User user, string channel) _onUserJoin;
    
    /++
        Called when a user joins a channel.
        
        Params:
            a = the user that joined
            b = the channel they joined
    +/
    @property typeof(_onUserJoin) onUserJoin()
    {
        return _onUserJoin;
    }
    
    /++
        ditto
    +/
    @property typeof(_onUserJoin) onUserJoin(typeof(_onUserJoin) newValue)
    {
        return _onUserJoin = newValue;
    }
    
    private void delegate(User user, string channel, string reason) _onUserPart;
    
    /++
        Called when a user leaves a channel.
        
        Params:
            a = the user that left
            b = the channel they left
            c = the reason they left, if any
    +/
    @property typeof(_onUserPart) onUserPart()
    {
        return _onUserPart;
    }
    
    /++
        ditto
    +/
    @property typeof(_onUserPart) onUserPart(typeof(_onUserPart) newValue)
    {
        return _onUserPart = newValue;
    }
    
    private void delegate(User user, string reason) _onUserQuit;
    
    /++
        Called when a user disconnects from the network.
        
        Params:
            a = the user that quit
            b = the reason they quit, if any
    +/
    @property typeof(_onUserQuit) onUserQuit()
    {
        return _onUserQuit;
    }
    
    /++
        ditto
    +/
    @property typeof(_onUserQuit) onUserQuit(typeof(_onUserQuit) newValue)
    {
        return _onUserQuit = newValue;
    }
    
    private void delegate(User kicker, string user, string channel, string reason) _onUserKick;
    
    /++
        Called when a user is kicked from a channel.
        
        Params:
            a = the user that performed the kick
            b = the user that was kicked
            c = the channel they were kicked from
            d = the reason they were kicked
    +/
    @property typeof(_onUserKick) onUserKick()
    {
        return _onUserKick;
    }
    
    /++
        ditto
    +/
    @property typeof(_onUserKick) onUserKick(typeof(_onUserKick) newValue)
    {
        return _onUserKick = newValue;
    }
    
    private void delegate(User user, string oldNick) _onUserRename;
    
    /++
        Called when a user changes their nickname.
        
        Params:
            a = the user that changed their name
            b = the user's old name
    +/
    @property typeof(_onUserRename) onUserRename()
    {
        return _onUserRename;
    }
    
    /++
        ditto
    +/
    @property typeof(_onUserRename) onUserRename(typeof(_onUserRename) newValue)
    {
        return _onUserRename = newValue;
    }
    
    /*======================================*
     *======================================*
     *           Private Methods            *
     *======================================*
     *======================================*/
    
    private void protocolLoop(string password)
    in { assert(transport && transport.connected); }
    body
    {
        import vibe.core.log: logError;
        import vibe.core.core: sleep;
        
        string disconnectReason = "Connection terminated gracefully";
        
        version(IrcDebugLogging) logDebug("irc connected");
        
        if(runCallback(onConnect)) //TODO: flip meaning of return type
        {
            if(password != null)
                sendLine("PASS %s", password);
            
            sendLine("NICK %s", nickname);
            sendLine("USER %s 0 * :%s", username, realname);
        }
        
        while(transport.connected)
        {
            string line;
            
            if(buffering)
                flushMessageBuffer;
            
            try
                line = transport.tryReadLine;
            catch(Exception err)
            {
                logError(err.toString);
                
                break;
            }
            
            if(line == null)
            {
                sleep(sleepTimeout);
                
                continue;
            }
            
            version(IrcDebugLogging) logDebug("irc recv: %s", line);
            
            try
                lineReceived(line);
            catch(GracelessDisconnect err)
            {
                disconnectReason = err.msg;
                
                transport.close;
            }
        }
        
        runCallback(onDisconnect, disconnectReason);
        version(IrcDebugLogging) logDebug("irc disconnected");
    }
    
    private void lineReceived(string line)
    {
        import std.conv: ConvException, to;
        import std.string: split;
        
        string[] parts = line.split(" ");
        
        switch(parts[0])
        {
            case "PING":
                sendLine("PONG %s", parts[1]);
                
                break;
            case "ERROR":
                throw new GracelessDisconnect(parts.dropFirst.join.dropFirst);
            default:
                parts[0] = parts[0].dropFirst;
                
                try
                    handleNumeric(parts[0], parts[1].to!int, parts[2 .. $]);
                catch(ConvException err)
                    handleCommand(parts[0], parts[1], parts[2 .. $]);
        }
    }
    
    private void handleCommand(string prefix, string command, string[] parts)
    {
        version(IrcDebugLogging) logDebug("handleCommand(%s, %s, %s)", prefix, command, parts);
        
        switch(command)
        {
            case "NOTICE":
            case "PRIVMSG":
                Message msg;
                string message = parts.dropFirst.join;
                msg.sender = prefix.splitUserinfo;
                msg.target = parts[0];
                msg.message = message != null ? message.dropFirst : "";
                
                if(message.isCTCP)
                {
                    auto parsedCtcp = message.parseCTCP;
                    msg.ctcpCommand = parsedCtcp.command;
                    msg.message = parsedCtcp.message;
                }
                
                if(command == "NOTICE")
                    runCallback(onNotice, msg);
                else
                    runCallback(onMessage, msg);
                
                break;
            case "JOIN":
                runCallback(onUserJoin, prefix.splitUserinfo, parts[0].dropFirst);
                
                break;
            case "PART":
                runCallback(onUserPart, prefix.splitUserinfo, parts[0], parts.dropFirst.join.dropFirst);
                
                break;
            case "QUIT":
                runCallback(onUserQuit, prefix.splitUserinfo, parts.join.dropFirst);
                
                break;
            case "NICK":
                runCallback(onUserRename, prefix.splitUserinfo, parts[0].dropFirst);
                
                break;
            case "KICK":
                runCallback(onUserKick, prefix.splitUserinfo, parts[1], parts[0], parts[2 .. $].join.dropFirst);
                
                break;
            default:
                runCallback(onUnknownCommand, prefix, command, parts);
        }
    }
    
    private void handleNumeric(string prefix, int id, string[] parts)
    {
        version(IrcDebugLogging) logDebug("handleNumeric(%s, %s, %s)", prefix, id, parts);
        
        switch(id)
        {
            case Numeric.RPL_WELCOME:
                onLogin;
                
                break;
            case Numeric.ERR_ERRONEUSNICKNAME:
                throw new GracelessDisconnect("Erroneus nickname"); //TODO: handle gracefully?
            case Numeric.ERR_NICKNAMEINUSE:
                throw new GracelessDisconnect("Nickname already in use"); //TODO: handle gracefully?
            default:
                runCallback(onUnknownNumeric, prefix, id, parts);
        }
    }
    
    private void flushMessageBuffer()
    {
        import std.datetime: Clock;
        
        version(IrcDebugLogging) uint currentSend = 0;
        
        void updateTime()
        {
            bufferNextTime = Clock.currTime + bufferTimeout + dur!"seconds"(1); //add a second just to be safe
        }
        
        if(buffer.length == 0)
            return;
        
        if(Clock.currTime > bufferNextTime)
        {
            bufferSent = 0;
            
            updateTime;
        }
        
        if(bufferSent >= bufferLimit)
            return;
        
        version(IrcDebugLogging) logDebug("irc flushMessageBuffer: about to send, %s so far this period", bufferSent);
        
        while(true)
        {
            if(buffer.length == 0)
            {
                version(IrcDebugLogging) logDebug("irc flushMessageBuffer: ran out of messages");
                
                break;
            }
            
            if(bufferSent >= bufferLimit)
            {
                version(IrcDebugLogging) logDebug("irc flushMessageBuffer: hit buffering limit");
                
                break;
            }
            
            string line = buffer[0];
            buffer = buffer[1 .. $];
            bufferSent++;
            version(IrcDebugLogging) currentSend++;
            
            version(IrcDebugLogging) logDebug("irc send: %s", line);
            transport.write(line ~ "\r\n");
        }
        
        updateTime;
        
        version(IrcDebugLogging) logDebug("irc flushMessageBuffer: sent %s this loop", currentSend);
    }
    
    private auto runCallback(CallbackType, Args...)(CallbackType callback, Args args)
    {
        static assert(
            isCallable!callback,
            "runCallback passed a non-delegate: " ~ CallbackType.stringof
        );
        static assert(
            __traits(compiles, callback(args)),
            "Cannot call " ~ CallbackType.stringof ~ " with types " ~ Args.stringof
        );
        
        if(callback !is null)
            return callback(args);
        else
        {
            alias returnType = ReturnType!callback;
            
            static if(is(returnType == void))
                return;
            else
                return returnType.init;
        }
    }
    
    /*======================================*
     *======================================*
     *            Public Methods            *
     *======================================*
     *======================================*/
    
    /++
        Connect to the IRC network and start the protocol loop.
        
        Params:
            host = hostname/address to connect to
            port = port to connect on
            password = password to use when logging in to the network (optional)
    +/
    void connect(string host, ushort port, string password = null)
    in { assert(transport is null ? true : !transport.connected); }
    body
    {
        import vibe.core.net: connectTCP;
        import vibe.core.core: runTask;
        
        //TODO: check if already connected
        
        transport = connectTCP(host, port);
        protocolTask = runTask(&protocolLoop, password);
    }
    
    /++
        Disconnect from the network, giving reason as the quit message.
    +/
    void quit(string reason)
    in { assert(transport && transport.connected); }
    body
    {
        sendLine("QUIT :%s", reason);
        
        if(Task.getThis !is protocolTask)
            protocolTask.join;
        
        transport.close;
    }
    
    /++
        Send a raw IRC command.
        
        Params:
            contents = format string for the line
            args = formatting arguments
    +/
    void sendLine(Args...)(string contents, Args args)
    in { assert(transport && transport.connected); }
    body
    {
        import std.string: format;
        
        contents = contents.format(args);
        
        if(buffering)
            buffer ~= contents;
        else
        {
            version(IrcDebugLogging) logDebug("irc send: %s", contents);
            transport.write(contents ~ "\r\n");
        }
    }
    
    /++
        Send a message.
        
        Params:
            destination = destination of the message, either a #channel or a nickname
            message = the body of the message
            notice = send a NOTICE instead of a PRIVMSG
    +/
    void send(string destination, string message, bool notice = false)
    {
        import std.string: split;
        
        foreach(line; message.split("\n"))
            sendLine("%s %s :%s", notice ? "NOTICE" : "PRIVMSG", destination, line);
    }
    
    /++
        Join a channel.
    +/
    void join(string name)
    {
        sendLine("JOIN %s", name);
    }
}
