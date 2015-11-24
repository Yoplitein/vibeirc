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
    Return type for the onConnect callback.
+/
enum PerformLogin
{
    /++
        Login procedure was not handled in user code, and needs to be done by the library.
    +/
    yes,
    
    /++
        Login procedure was handled in user code, and does not need to be done by the library.
    +/
    no,
} 

/++
    Represents a connection to an IRC server.
+/
final class IRCClient
{
    //placed here to prevent symbols leaking into user code
    import std.string: format, split;
    
    private Task protocolTask; //The task running protocolLoop
    private TCPConnection transport; //The TCP socket
    private string[] buffer; //Buffered messages
    private uint bufferSent; //Number of messages sent this time period
    private SysTime bufferNextTime; //The start of the next time period
    private SysTime lastIncomingLineTime; //When we last received a line from the server
    private bool sentPing; //Whether we sent a PING
    private bool receivedPong; //Whether the server has answered our PING
    
    /*======================================*
     *======================================*
     *              Properties              *
     *======================================*
     *======================================*/
    
    private string _nickname = "vibeirc";
    
    /++
        The display name this client will use.
        
        Defaults to vibeirc.
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
        if(connected)
            sendLine("NICK %s", newNick);
        
        return _nickname = newNick;
    }
    
    private string _username = "vibeirc";
    
    /++
        The username shown by the WHOIS command.
        
        Defaults to vibeirc.
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
    
    private string _realname = "vibeirc";
    
    /++
        The real name shown by the WHOIS command.
        
        Defaults to vibeirc.
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
    
    /++
        Returns whether this connection is active.
    +/
    @property bool connected()
    {
        return transport && transport.connected;
    }
    
    private bool _loggedIn;
    
    /++
        Whether or not this connection has successfully logged in to the network.
    +/
    @property bool loggedIn()
    {
        return _loggedIn;
    }
    
    /++
        ditto
    +/
    @property bool loggedIn(bool newValue)
    {
        return _loggedIn = newValue;
    }
    
    private string _serverHostname;
    
    /++
        The hostname of the server this client is connected to.
    +/
    @property string serverHostname()
    {
        return _serverHostname;
    }
    
    /++
        ditto
    +/
    @property string serverHostname(string newValue)
    {
        return _serverHostname = newValue;
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
    
    private PerformLogin delegate() _onConnect;
    
    /++
        Called after the connection is established, before logging in to the network.
        
        Returns:
            whether login procedure (sending of PASSWORD, NICK and USER commands)
            was handled in the callback
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
    
    private void delegate(User user, string newNick) _onUserRename;
    
    /++
        Called when a user changes their nickname.
        
        Params:
            a = the user that changed their name
            b = the user's new name
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
    in { assert(connected); }
    body
    {
        import vibe.core.log: logError;
        import vibe.core.core: sleep;
        
        version(IrcDebugLogging) logDebug("irc connected");
        
        if(runCallback(onConnect) == PerformLogin.yes)
        {
            if(password != null)
                sendLine("PASS %s", password);
            
            sendLine("NICK %s", nickname);
            sendLine("USER %s 0 * :%s", username, realname);
        }
        
        while(true)
        {
            string line;
            
            if(buffering)
                flushMessageBuffer;
            
            checkPingTime;
            
            try
                line = transport.tryReadLine;
            catch(Exception err)
            {
                logError(err.toString);
                
                break;
            }
            
            if(line == null)
            {
                if(!connected) //reading final lines
                    break;
                
                sleep(sleepTimeout);
                
                continue;
            }
            
            version(IrcDebugLogging) logDebug("irc recv: %s", line);
            lineReceived(line);
        }
        
        loggedIn = false;
        
        version(IrcDebugLogging) logDebug("irc disconnected");
    }
    
    private void lineReceived(string line)
    {
        import std.conv: ConvException, to;
        
        lastIncomingLineTime = Clock.currTime;
        string[] parts = line.split(" ");
        
        //commands of the form `CMD :data` are handled here
        //handleCommand and handleNumeric are for `:origin CMD :data`
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
                string message = parts.dropFirst.join.dropFirst;
                msg.sender = prefix.splitUserinfo;
                msg.target = parts[0];
                msg.message = message;
                
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
            case "PONG":
                receivedPong = true;
                
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
                version(IrcDebugLogging) logDebug("irc logged in");
                
                loggedIn = true;
                serverHostname = prefix;
                
                runCallback(onLogin);
                
                break;
            case Numeric.ERR_ERRONEUSNICKNAME:
                if(!loggedIn)
                    throw new GracelessDisconnect("Erroneus nickname");
                
                break;
            case Numeric.ERR_NICKNAMEINUSE:
                if(!loggedIn)
                    throw new GracelessDisconnect("Nickname already in use");
                
                break;
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
            static if(is(ReturnType!callback == void))
                return;
            else
                return ReturnType!callback.init;
        }
    }
    
    private void checkPingTime()
    {
        //how long to wait before sending a PING
        static const timeUntilSendPing = 1.minutes;
        //how long to wait after sending PING before considering the connection closed
        static const timeUntilErroring = 15.seconds;
        auto now = Clock.currTime;
        auto nextPing = lastIncomingLineTime + timeUntilSendPing;
        
        if(receivedPong)
        {
            receivedPong = false;
            sentPing = false;
            
            return;
        }
        
        if(now < nextPing)
            return;
        
        if(sentPing)
        {
            if(now < nextPing + timeUntilErroring)
                return;
            
            throw new GracelessDisconnect("Connection timed out");
        }
        
        sendLine("PING :%s", serverHostname);
        
        sentPing = true;
    }
    
    private void resetFields()
    {
        protocolTask = Task.init;
        transport = TCPConnection.init;
        buffer.length = 0;
        bufferSent = 0;
        bufferNextTime = Clock.currTime;
        lastIncomingLineTime = Clock.currTime;
        sentPing = false;
        receivedPong = false;
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
    {
        import vibe.core.net: connectTCP;
        import vibe.core.core: runTask;
        
        if(connected)
            throw new Exception("Already connected!");
        
        resetFields;
        
        string disconnectReason = "Connection terminated gracefully";
        protocolTask = runTask(
            {
                version(IrcDebugLogging) logDebug("Starting protocol loop");
                
                try
                {
                    transport = connectTCP(host, port);
                    
                    protocolLoop(password);
                }
                catch(Exception err)
                {
                    if(cast(GracelessDisconnect)err)
                        disconnectReason = err.msg;
                    else
                        disconnectReason = "%s: %s".format(typeid(err).name, err.msg);
                    
                    if(connected)
                        transport.close;
                }
                
                runCallback(onDisconnect, disconnectReason);
            }
        );
    }
    
    /++
        Disconnect from the network, giving reason as the quit message.
    +/
    void quit(string reason)
    in { assert(connected); }
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
    in { assert(connected); }
    body
    {
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
