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
    import std.string: split, format;
    
    import vibe.core.stream: InputStream;
}

private enum CTCP_ENCAPSULATOR = '\x01';

enum
{
    /++
        The server sends RPL_WELCOME through RPL_MYINFO to a user upon successful registration.
    +/
    RPL_WELCOME = 001,
    RPL_YOURHOST = 002, ///ditto
    RPL_CREATED = 003, ///ditto
    RPL_MYINFO = 004, ///ditto
    
    /++
        Sent by the server to a user to suggest an alternative server.
        This is often used when the connection is refused because the server is already full.
    +/
    RPL_BOUNCE = 005,
    
    /++
        Reply format used by USERHOST to list replies to the query list.
    +/
    RPL_USERHOST = 302,
    
    /++
        Reply format used by ISON to list replies to the query list.
    +/
    RPL_ISON = 303,
    
    /++
        These replies are used with the AWAY command (if allowed).
        RPL_AWAY is sent to any client sending a PRIVMSG to a client which is away.
        RPL_AWAY is only sent by the server to which the client is connected.
        Replies RPL_UNAWAY and RPL_NOWAWAY are sent when the client removes and sets an AWAY message.
    +/
    RPL_AWAY = 301,
    RPL_UNAWAY = 305, ///ditto
    RPL_NOWAWAY = 306, ///ditto
    
    /++
        Replies RPL_WHOISUSER through RPL_WHOIS, RPL_WHOISIDLE through RPL_WHOISCHANNELS are all replies generated in response to a WHOIS message.
        Given that there are enough parameters present,
        the answering server MUST either formulate a reply out of the above numerics
        (if the query nick is found) or return an error reply.
        The '*' in RPL_WHOISUSER is there as the literal character and not as a wild card.
        For each reply set, only RPL_WHOISCHANNELS may appear more than once
        (for long lists of channel names).
        The '@' and '+' characters next to the channel name indicate whether
        a client is a channel operator or has been granted permission to speak on a moderated channel.
        The RPL_ENDOFWHOIS reply is used to mark the end of processing a WHOIS message.
    +/
    RPL_WHOISUSER = 311,
    RPL_WHOISSERVER = 312, ///ditto
    RPL_WHOISOPERATOR = 313, ///ditto
    RPL_WHOISIDLE = 317, ///ditto
    RPL_ENDOFWHOIS = 318, ///ditto
    RPL_WHOISCHANNELS = 319, ///ditto
    
    /++
        When replying to a WHOWAS message, a server MUST use the replies
        RPL_WHOWASUSER, RPL_WHOISSERVER or ERR_WASNOSUCHNICK for each nickname in the presented list.
        At the end of all reply batches, there MUST be RPL_ENDOFWHOWAS
        (even if there was only one reply and it was an error).
    +/
    RPL_WHOWASUSER = 314,
    RPL_ENDOFWHOWAS = 369, ///ditto
    
    /++
        Replies RPL_LIST, RPL_LISTEND mark the actual replies with data
        and end of the server's responseto a LIST command.
        If there are no channels available to return,  only the end reply MUST be sent.
    +/
    RPL_LIST = 322, ///ditto
    RPL_LISTEND = 323, ///ditto
    RPL_LISTSTART = 321, ///Obsolete. Not used.
    
    RPL_UNIQOPIS = 325, ///
    RPL_CHANNELMODEIS = 324, ///
    
    /++
        When sending a TOPIC message to determine the channel topic, one of two replies is sent.
        If the topic is set, RPL_TOPIC is sent back else RPL_NOTOPIC.
    +/
    RPL_NOTOPIC = 331, ///ditto
    RPL_TOPIC = 332, ///ditto
    
    /++
        Returned by the server to indicate that the attempted INVITE message
        was successful and is being passed onto the end client.
    +/
    RPL_INVITING = 341,
    
    /++
        Returned by a server answering a SUMMON message to indicate that it is summoning that user.
    +/
    RPL_SUMMONING = 342,
    
    /++
        When listing the 'invitations masks' for a given channel,
        a server is required to send the list back using the RPL_INVITELIST
        and RPL_ENDOFINVITELIST messages.
        A separate RPL_INVITELIST is sent for each active mask.
        After the masks have been listed (or if none present)
        a RPL_ENDOFINVITELIST MUST be sent.
    +/
    RPL_INVITELIST = 346,
    RPL_ENDOFINVITELIST = 347, ///ditto
    
    /++
        When listing the 'exception masks' for a given channel,
        a server is required to send the list back using the RPL_EXCEPTLIST
        and RPL_ENDOFEXCEPTLIST messages.
        A separate RPL_EXCEPTLIST is sent for each active mask.
        After the masks have been listed (or if none present)
        a RPL_ENDOFEXCEPTLIST MUST be sent.
    +/
    RPL_EXCEPTLIST = 348,
    RPL_ENDOFEXCEPTLIST = 349, ///ditto
    
    /++
        Reply by the server showing its version details.
    +/
    RPL_VERSION = 351,
    
    /++
        The RPL_WHOREPLY and RPL_ENDOFWHO pair are used to answer a WHO message.
        The RPL_WHOREPLY is only sent if there is an appropriate match to the WHO query.
    +/
    RPL_WHOREPLY = 352,
    RPL_ENDOFWHO = 315, ///ditto
    
    /++
        To reply to a NAMES message, a reply pair consisting of RPL_NAMREPLY
        and RPL_ENDOFNAMES is sent by the server back to the client.
        If there is no channel found as in the query, then only RPL_ENDOFNAMES is returned.
        The exception to this is when a NAMES message is sent with no parameters
        and all visible channels and contents are sent back in a series of
        RPL_NAMEREPLY messages with a RPL_ENDOFNAMES to mark the end.
    +/
    RPL_NAMREPLY = 353,
    RPL_ENDOFNAMES = 366, ///ditto
    
    /++
        In replying to the LINKS message, a server MUST send replies back using the RPL_LINKS
        numeric and mark the end of the list using an RPL_ENDOFLINKS reply.
    +/
    RPL_LINKS = 364,
    RPL_ENDOFLINKS = 365, ///ditto
    
    /++
        When listing the active 'bans' for a given channel, a server is required
        to send the list back using the RPL_BANLIST and RPL_ENDOFBANLIST messages.
        A separate RPL_BANLIST is sent for each active banmask.
        After the banmasks have been listed (or if none present) a RPL_ENDOFBANLIST MUST be sent.
    +/
    RPL_BANLIST = 367,
    RPL_ENDOFBANLIST = 368, ///ditto
    
    /++
        A server responding to an INFO message is required to send all its 'info' in a series of
        RPL_INFO messages with a RPL_ENDOFINFO reply to indicate the end of the replies.
    +/
    RPL_INFO = 371,
    RPL_ENDOFINFO = 374, ///ditto
    
    /++
        When responding to the MOTD message and the MOTD file is found,
        the file is displayed line by line, with each line no longer than 80 characters,
        using RPL_MOTD format replies.
        These MUST be surrounded by a RPL_MOTDSTART (before the RPL_MOTDs)
        and an RPL_ENDOFMOTD (after).
    +/
    RPL_MOTDSTART = 375,
    RPL_MOTD = 372, ///ditto
    RPL_ENDOFMOTD = 376, ///ditto
    
    /++
        RPL_YOUREOPER is sent back to a client which has just successfully issued
        an OPER message and gained operator status.
    +/
    RPL_YOUREOPER = 381,
    
    /++
        If the REHASH option is used and an operator sends a REHASH message,
        an RPL_REHASHING is sent back to the operator.
    +/
    RPL_REHASHING = 382,
    
    /++
        Sent by the server to a service upon successful registration.
    +/
    RPL_YOURESERVICE = 383,
    
    /++
        When replying to the TIME message, a server MUST send the reply using the RPL_TIME format above.
        The string showing the time need only contain the correct day and time there.
        There is no further requirement for the time string.
    +/
    RPL_TIME = 391,
    
    /++
        If the USERS message is handled by a server, the replies RPL_USERSTART,
        RPL_USERS, RPL_ENDOFUSERS and RPL_NOUSERS are used.
        RPL_USERSSTART MUST be sent first, following by either a sequence of RPL_USERS
        or a single RPL_NOUSER.
        Following this is RPL_ENDOFUSERS.
    +/
    RPL_USERSSTART = 392,
    RPL_USERS = 393, ///ditto
    RPL_ENDOFUSERS = 394, ///ditto
    RPL_NOUSERS = 395, ///ditto
    
    /++
        The RPL_TRACE* are all returned by the server in response to the TRACE message.
        How many are returned is dependent on the TRACE message and whether it was sent by an operator or not.
        There is no predefined order for which occurs first.
        Replies RPL_TRACEUNKNOWN, RPL_TRACECONNECTING and RPL_TRACEHANDSHAKE are all used for connections
        which have not been fully established and are either unknown,
        still attempting to connect or in the process of completing the 'server handshake'.
        RPL_TRACELINK is sent by any server which handlesa TRACE message and has to pass it on to another server.
        The list of RPL_TRACELINKs sent in response to a TRACE command traversing the IRC network
        should reflect the actual connectivity ofthe servers themselves along that path.
        RPL_TRACENEWTYPE is to be used for any connection which does not fit in the other categories
        but is being displayed anyway.
        RPL_TRACEEND is sent to indicate the end of the list.
    +/
    RPL_TRACELINK = 200,
    RPL_TRACECONNECTING = 201, ///ditto
    RPL_TRACEHANDSHAKE = 202, ///ditto
    RPL_TRACEUNKNOWN = 203, ///ditto
    RPL_TRACEOPERATOR = 204, ///ditto
    RPL_TRACEUSER = 205, ///ditto
    RPL_TRACESERVER = 206, ///ditto
    RPL_TRACESERVICE = 207, ///ditto
    RPL_TRACENEWTYPE = 208, ///ditto
    RPL_TRACECLASS = 209, ///ditto
    RPL_TRACELOG = 261, ///ditto
    RPL_TRACEEND = 262, ///ditto
    RPL_TRACERECONNECT = 210, ///Unused.
    
    /++
        Returned from the server in response to the STATS message.
    +/
    RPL_STATSLINKINFO = 211,
    RPL_STATSCOMMANDS = 212, ///ditto
    RPL_ENDOFSTATS = 219, ///ditto
    RPL_STATSUPTIME = 242, ///ditto
    RPL_STATSOLINE = 243, ///ditto
    
    RPL_UMODEIS = 221, ///
    
    RPL_SERVLIST = 234, ///
    
    /++
        When listing services in reply to a SERVLIST message,
        a server is required to send the list back using the RPL_SERVLIST
        and RPL_SERVLISTEND messages.
        A separate RPL_SERVLIST is sent for each service.
        After the services have been listed (or if none present) a RPL_SERVLISTEND MUST be sent.
    +/
    RPL_SERVLISTEND = 235,
    
    /++
        In processing an LUSERS message, the server sends a set of replies from
        RPL_LUSERCLIENT, RPL_LUSEROP, RPL_USERUNKNOWN, RPL_LUSERCHANNELS and RPL_LUSERME.
        When replying, a server MUST send back RPL_LUSERCLIENT and RPL_LUSERME.
        The other replies are only sent back if a non-zero count is found for them.
    +/
    RPL_LUSERCLIENT = 251,
    RPL_LUSEROP = 252,  ///ditto
    RPL_LUSERUNKNOWN = 253,  ///ditto
    RPL_LUSERCHANNELS = 254,  ///ditto
    RPL_LUSERME = 255,  ///ditto
    
    /++
        When replying to an ADMIN message, a server is expected to use replies RPL_ADMINME
        through to RPL_ADMINEMAIL and provide a text message with each.
        For RPL_ADMINLOC1 a description of what city, state and country the server is in is expected,
        followed by details of the institution (RPL_ADMINLOC2)
        and finally the administrative contact for the server (an email address here is REQUIRED)
        in RPL_ADMINEMAIL.
    +/
    RPL_ADMINME = 256,
    RPL_ADMINLOC1 = 257,  ///ditto
    RPL_ADMINLOC2 = 258,  ///ditto
    RPL_ADMINEMAIL = 259,  ///ditto
    
    /++
        When a server drops a command without processing it,
        it MUST use the reply RPL_TRYAGAIN to inform the originating client.
    +/
    RPL_TRYAGAIN = 263,
    
    /++
        Used to indicate the nickname parameter supplied to a command is currently unused.
    +/
    ERR_NOSUCHNICK = 401,
    
    /++
        Used to indicate the server name given currently does not exist.
    +/
    ERR_NOSUCHSERVER = 402,
    
    /++
        Used to indicate the given channel name is invalid.
    +/
    ERR_NOSUCHCHANNEL = 403,
    
    /++
        Sent to a user who is either (a) not on a channel which is mode +n
        or (b) not a chanop (or mode +v) on a channel which has mode +m set
        or where the user is banned and is trying to send a PRIVMSG message to that channel.
    +/
    ERR_CANNOTSENDTOCHAN = 404,
    
    /++
        Sent to a user when they have joined the maximum number
        of allowed channels and they try to join another channel.
    +/
    ERR_TOOMANYCHANNELS = 405,
    
    /++
        Returned by WHOWAS to indicate there is no history information for that nickname.
    +/
    ERR_WASNOSUCHNICK = 406,
    
    /++
        Returned to a client which is attempting to send a PRIVMSG/NOTICE
        using the user@host destination format and for a user@host which has several occurrences.
        Returned to a client which trying to send a PRIVMSG/NOTICE to too many recipients.
        Returned to a client which is attempting to JOIN a safe channel
        using the shortname when there are more than one such channel.
    +/
    ERR_TOOMANYTARGETS = 407,
    
    /++
        Returned to a client which is attempting to send a SQUERY to a service which does not exist.
    +/
    ERR_NOSUCHSERVICE = 408,
    
    /++
        PING or PONG message missing the originator parameter.
    +/
    ERR_NOORIGIN = 409,
    
    /++
        ERR_NOTEXTTOSEND through ERR_BADMASK are returned by PRIVMSG to indicate that the message
        wasn't delivered for some reason.
        ERR_NOTOPLEVEL and ERR_WILDTOPLEVEL are errors that are returned
        when an invalid use of "PRIVMSG $<server>" or "PRIVMSG #<host>" is attempted.
    +/
    ERR_NORECIPIENT = 411,
    ERR_NOTEXTTOSEND = 412,  ///ditto
    ERR_NOTOPLEVEL = 413,  ///ditto
    ERR_WILDTOPLEVEL = 414,  ///ditto
    ERR_BADMASK = 415,  ///ditto
    
    /++
        Returned to a registered client to indicate
        that the command sent is unknown by the server.
    +/
    ERR_UNKNOWNCOMMAND = 421,
    
    /++
        Server's MOTD file could not be opened by the server.
    +/
    ERR_NOMOTD = 422,
    
    /++
        Returned by a server in response to an ADMIN message
        when there is an error in finding the appropriate information.
    +/
    ERR_NOADMININFO = 423,
    
    /++
        Generic error message used to report a failed file
        operation during the processing of a message.
    +/
    ERR_FILEERROR = 424,
    
    /++
        Returned when a nickname parameter expected for a command and isn't found.
    +/
    ERR_NONICKNAMEGIVEN = 431,
    
    /++
        Returned after receiving a NICK message
        which contains characters which do not fall in the defined set.
    +/
    ERR_ERRONEUSNICKNAME = 432,
    
    /++
        Returned when a NICK message is processed that results
        in an attempt to change to a currently existing nickname.
    +/
    ERR_NICKNAMEINUSE = 433,
    
    /++
        Returned by a server to a client when it detects a nickname collision
        (registered of a NICK that already exists by another server).
    +/
    ERR_NICKCOLLISION = 436,
}

enum
{
    /++
        Color codes for use with $(SYMBOL_LINK color).
    +/
    WHITE = "00",
    BLACK = "01", ///ditto
    BLUE = "02", ///ditto
    GREEN = "03", ///ditto
    RED = "04", ///ditto
    BROWN = "05", ///ditto
    PURPLE = "06", ///ditto
    ORANGE = "07", ///ditto
    YELLOW = "08", ///ditto
    LIGHTGREEN = "09", ///ditto
    TEAL = "10", ///ditto
    LIGHTCYAN = "11", ///ditto
    LIGHTBLUE = "12", ///ditto
    PINK = "13", ///ditto
    GREY = "14", ///ditto
    LIGHTGREY = "15", ///ditto
    TRANSPARENT = "99", ///ditto
}

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
    import std.datetime: SysTime, Duration, dur;
    
    import vibe.core.net: TCPConnection;
    import vibe.core.log: logDebug;
    import vibe.core.task: Task;
    
    private string _nickname;
    private Task protocolTask;
    private string[] buffer; //Buffered messages
    private uint bufferSent = 0; //Number of messages sent this time period
    private SysTime bufferNextTime; //The start of the next time period
    ConnectionParameters connectionParameters; ///The connection parameters passed to $(SYMBOL_LINK irc_connect).
    TCPConnection transport; ///The vibe socket underlying this connection.
    Duration sleepTimeout = dur!"msecs"(10); ///How long the protocol loop should sleep after failing to read a line.
    bool buffering = false; ///Whether to buffer outgoing messages.
    uint bufferLimit = 20; ///Maximum number of messages to send per time period, if buffering is enabled.
    Duration bufferTimeout = dur!"seconds"(30); ///Amount of time to wait before sending each batch of messages, if buffering is enabled.
    
    /++
        Default constructor. Should not be called from user code.
        
        See_Also:
            $(SYMBOL_LINK irc_connect)
    +/
    protected this()
    {
        bufferNextTime = SysTime(0L);
    }
    
    private void protocol_loop()
    in { assert(transport && transport.connected); }
    body
    {
        import vibe.core.log: logError;
        import vibe.core.core: sleep;
        
        string disconnectReason = "Connection terminated gracefully";
        
        version(IrcDebugLogging) logDebug("irc connected");
        
        if(connected)
        {
            if(connectionParameters.password != null)
                send_line("PASS %s", connectionParameters.password);
            
            send_line("NICK %s", nickname);
            send_line("USER %s 0 * :%s", connectionParameters.username, connectionParameters.realname);
        }
        
        while(transport.connected)
        {
            string line;
            
            if(buffering)
                send_messages;
            
            try
                line = transport.read_line;
            catch(Exception err)
            {
                logError(err.toString);
                
                break;
            }
            
            if(line == null)
            {
                sleep(dur!"msecs"(10));
                
                continue;
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
        version(IrcDebugLogging) logDebug("irc disconnected");
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
        version(IrcDebugLogging) logDebug("handle_command(%s, %s, %s)", prefix, command, parts);
        
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
        version(IrcDebugLogging) logDebug("handle_numeric(%s, %s, %s)", prefix, id, parts);
        
        switch(id)
        {
            case RPL_WELCOME:
                signed_on;
                
                break;
            case ERR_ERRONEUSNICKNAME:
                throw new GracelessDisconnect("Erroneus nickname"); //TODO: handle gracefully?
            case ERR_NICKNAMEINUSE:
                throw new GracelessDisconnect("Nickname already in use"); //TODO: handle gracefully?
            default:
                unknown_numeric(prefix, id, parts);
        }
    }
    
    private void send_messages()
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
        
        version(IrcDebugLogging) logDebug("irc send_messages: about to send, %s so far this period", bufferSent);
        
        while(true)
        {
            if(buffer.length == 0)
            {
                version(IrcDebugLogging) logDebug("irc send_messages: ran out of messages");
                
                break;
            }
            
            if(bufferSent >= bufferLimit)
            {
                version(IrcDebugLogging) logDebug("irc send_messages: hit buffering limit");
                
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
        
        version(IrcDebugLogging) logDebug("irc send_messages: sent %s this loop", currentSend);
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
    
    /++
        Connect to the IRC network and start the protocol loop.
        
        Called from $(SYMBOL_LINK irc_connect), so calling this is only necessary for reconnects.
    +/
    final void connect()
    in { assert(transport is null ? true : !transport.connected); }
    body
    {
        import vibe.core.net: connectTCP;
        import vibe.core.core: runTask;
        
        transport = connectTCP(connectionParameters.hostname, connectionParameters.port);
        protocolTask = runTask(&protocol_loop);
    }
    
    /++
        Disconnect from the network, giving reason as the quit message.
    +/
    final void disconnect(string reason)
    in { assert(transport && transport.connected); }
    body
    {
        send_line("QUIT :%s", reason);
        
        if(Task.getThis !is protocolTask)
            protocolTask.join;
        
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
            notice = send a NOTICE instead of a PRIVMSG
    +/
    final void send_message(string destination, string message, bool notice = false)
    {
        foreach(line; message.split("\n"))
            send_line("%s %s :%s", notice ? "NOTICE" : "PRIVMSG", destination, line);
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
    void signed_on() {}
    
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

private User split_userinfo(string info)
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

/+
    Replacement for vibe.stream.operations.readLine that either reads a line immediately,
    or returns null if a line could not be read.
+/
private string read_line(InputStream stream, string terminator = "\r\n")
{
    import std.algorithm: countUntil;
    
    const peekBuffer = stream.peek;
    
    if(peekBuffer.length == 0)
        return null;
    
    auto length = peekBuffer.countUntil(cast(ubyte[])terminator);
    
    if(length == -1)
        return null;
    
    auto buffer = new ubyte[length];
    
    stream.read(buffer);
    
    auto line = cast(string)buffer.idup;
    buffer.length = terminator.length;
    
    stream.read(buffer); //clear terminator
    
    return line;
}

unittest
{
    import vibe.stream.memory: MemoryStream;
    
    auto buffer = new MemoryStream(cast(ubyte[])"abc\r\ndef");
    
    assert(buffer.read_line == "abc");
    assert(buffer.peek == "def");
}
