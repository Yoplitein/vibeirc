///
module vibeirc.constants;

package enum CTCP_ENCAPSULATOR = '\x01';

/++
    Color codes for use with $(SYMBOL_LINK color).
+/
enum Color: string
{
    none = null, ///Default color
    white = "00", ///
    black = "01", ///
    blue = "02", ///
    green = "03", ///
    red = "04", ///
    brown = "05", ///
    purple = "06", ///
    orange = "07", ///
    yellow = "08", ///
    lightgreen = "09", ///
    teal = "10", ///
    lightcyan = "11", ///
    lightblue = "12", ///
    pink = "13", ///
    grey = "14", ///
    lightgrey = "15", ///
    transparent = "99", ///
}

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
