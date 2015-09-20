///
module vibeirc.client;

import std.datetime;

import vibe.core.log;
import vibe.core.net;
import vibe.core.task;

import vibeirc.constants;
import vibeirc.data;
import vibeirc.utility;

/++
    Represents a connection to an IRC server.
+/
final class IRCClient
{
    private Task protocolTask;
    private string[] buffer; //Buffered messages
    private uint bufferSent = 0; //Number of messages sent this time period
    private SysTime bufferNextTime; //The start of the next time period
    private TCPConnection transport;
    
    //TODO: getters/setters
    Duration sleepTimeout = dur!"msecs"(10); ///How long the protocol loop should sleep after failing to read a line.
    bool buffering = false; ///Whether to buffer outgoing messages.
    uint bufferLimit = 20; ///Maximum number of messages to send per time period, if buffering is enabled.
    Duration bufferTimeout = dur!"seconds"(30); ///Amount of time to wait before sending each batch of messages, if buffering is enabled.
    
    ///
    this()
    {
        bufferNextTime = SysTime(0L);
    }
    
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
    
    private void protocolLoop(string password)
    in { assert(transport && transport.connected); }
    body
    {
        import vibe.core.log: logError;
        import vibe.core.core: sleep;
        
        string disconnectReason = "Connection terminated gracefully";
        
        version(IrcDebugLogging) logDebug("irc connected");
        
        if(connected)
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
        
        disconnected(disconnectReason);
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
                    notice(msg);
                else
                    privmsg(msg);
                
                break;
            case "JOIN":
                userJoined(prefix.splitUserinfo, parts[0].dropFirst);
                
                break;
            case "PART":
                userLeft(prefix.splitUserinfo, parts[0], parts.dropFirst.join.dropFirst);
                
                break;
            case "QUIT":
                userQuit(prefix.splitUserinfo, parts.join.dropFirst);
                
                break;
            case "NICK":
                userRenamed(prefix.splitUserinfo, parts[0].dropFirst);
                
                break;
            case "KICK":
                userKicked(prefix.splitUserinfo, parts[1], parts[0], parts[2 .. $].join.dropFirst);
                
                break;
            default:
                unknownCommand(prefix, command, parts);
        }
    }
    
    private void handleNumeric(string prefix, int id, string[] parts)
    {
        version(IrcDebugLogging) logDebug("handleNumeric(%s, %s, %s)", prefix, id, parts);
        
        switch(id)
        {
            case Numeric.RPL_WELCOME:
                signedOn;
                
                break;
            case Numeric.ERR_ERRONEUSNICKNAME:
                throw new GracelessDisconnect("Erroneus nickname"); //TODO: handle gracefully?
            case Numeric.ERR_NICKNAMEINUSE:
                throw new GracelessDisconnect("Nickname already in use"); //TODO: handle gracefully?
            default:
                unknownNumeric(prefix, id, parts);
        }
    }
    
    private void flushMessageBuffer()
    {
        import std.datetime: Clock;
        
        version(IrcDebugLogging) uint currentSend = 0;
        
        void update_time()
        {
            bufferNextTime = Clock.currTime + bufferTimeout + dur!"seconds"(1); //add a second just to be safe
        }
        
        if(buffer.length == 0)
            return;
        
        if(Clock.currTime > bufferNextTime)
        {
            bufferSent = 0;
            
            update_time;
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
        
        update_time;
        
        version(IrcDebugLogging) logDebug("irc flushMessageBuffer: sent %s this loop", currentSend);
    }
    
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
        Send a _message.
        
        Params:
            destination = _destination of the message, either a #channel or a nickname
            message = the body of the _message
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
    
    /++
        Called when an unknown command is received.
        
        Params:
            prefix = origin of the _command, either a server or a user
            command = the name of the _command
            arguments = the body of the _command
    +/
    void unknownCommand(string prefix, string command, string[] arguments) {}
    
    /++
        Called when an unknown numeric command is received.
        
        Params:
            prefix = origin of the command, either a server or a user
            id = the number of the command
            arguments = the body of the command
    +/
    void unknownNumeric(string prefix, int id, string[] arguments) {}
    
    /++
        Called after the connection is established, before logging in to the network.
        
        Returns:
            whether to perform default login procedure
            (send PASSWORD, NICK and USER commands)
    +/
    bool connected()
    {
        return true;
    }
    
    /++
        Called after being _disconnected from the network.
    +/
    void disconnected(string reason) {}
    
    /++
        Called after succesfully logging in to the network.
    +/
    void signedOn() {}
    
    /++
        Called upon reception of an incoming message.
        
        Despite the name, it may have been sent either directly or to a channel.
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
    void userJoined(User user, string channel) {}
    
    /++
        Called when a _user leaves a _channel.
    +/
    void userLeft(User user, string channel, string reason) {}
    
    /++
        Called when a _user disconnects from the network.
    +/
    void userQuit(User user, string reason) {}
    
    /++
        Called when a _user is kicked from a _channel.
        
        Params:
            kicker = the _user that performed the kick
            user = the _user that was kicked
    +/
    void userKicked(User kicker, string user, string channel, string reason) {}
    
    /++
        Called when a _user changes their nickname.
    +/
    void userRenamed(User user, string oldNick) {}
}

