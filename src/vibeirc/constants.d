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

/++
    Numerics used in place of words in IRC commands.
    Only sent from the server.
+/
enum Numeric
{
    /++
        Sent after successfully logging in to the server.
    +/
    RPL_WELCOME = 001,
    
    /++
        ditto
    +/
    RPL_YOURHOST = 002,
    
    /++
        ditto
    +/
    RPL_CREATED = 003,
    
    /++
        ditto
    +/
    RPL_MYINFO = 004,
    
    /++
        Sent when the connection is refused, suggesting an alternate server.
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
        Reply from a command directed at a user who is marked as away.
    +/
    RPL_AWAY = 301,
    
    /++
        Reply from AWAY command when no longer marked as away.
    +/
    RPL_UNAWAY = 305,
    
    /++
        Reply from AWAY when marked as away.
    +/
    RPL_NOWAWAY = 306,
    
    /++
        Reply to WHOIS with information about the user.
    +/
    RPL_WHOISUSER = 311,
    
    /++
        Reply to WHOIS with information about the server the user is connected to.
    +/
    RPL_WHOISSERVER = 312,
    
    /++
        Reply to WHOIS indicating the operator status of the user.
    +/
    RPL_WHOISOPERATOR = 313,
    
    /++
        Reply to WHOIS with information about the user's idle status.
    +/
    RPL_WHOISIDLE = 317,
    
    /++
        End of replies to WHOIS command.
    +/
    RPL_ENDOFWHOIS = 318,
    
    /++
        Reply to WHOIS listing the channels the user has joined.
    +/
    RPL_WHOISCHANNELS = 319,
    
    /++
        Reply to WHOWAS with information about the user.
    +/
    RPL_WHOWASUSER = 314,
    
    /++
        End of replies to WHOWAS.
    +/
    RPL_ENDOFWHOWAS = 369,
    
    /++
        Reply to LIST containing a single channel.
    +/
    RPL_LIST = 322,
    
    /++
        End of replies to LIST.
    +/
    RPL_LISTEND = 323,
    
    /++
        Deprecated. Formerly indicated the start of a response to LIST command.
    +/
    RPL_LISTSTART = 321,
    
    /++
        Reply to a MODE command on a channel which does not change any modes.
    +/
    RPL_CHANNELMODEIS = 324,
    
    /++
        Reply to TOPIC if no topic is set.
    +/
    RPL_NOTOPIC = 331,
    
    /++
        Reply to TOPIC if a topic is set.
    +/
    RPL_TOPIC = 332,
    
    /++
        Reply to successful INVITE command.
    +/
    RPL_INVITING = 341,
    
    /++
        Reply to successful SUMMON command.
    +/
    RPL_SUMMONING = 342,
    
    /++
        A single listing of an invitation mask for a channel.
    +/
    RPL_INVITELIST = 346,
    
    /++
        End of RPL_INVITELIST replies.
    +/
    RPL_ENDOFINVITELIST = 347,
    
    /++
        A single listing of an exception mask for a channel.
    +/
    RPL_EXCEPTLIST = 348,
    
    /++
        End of RPL_EXCEPTLIST replies.
    +/
    RPL_ENDOFEXCEPTLIST = 349,
    
    /++
        Reply to VERSION command.
    +/
    RPL_VERSION = 351,
    
    /++
        Reply to WHO command.
    +/
    RPL_WHOREPLY = 352,
    
    /++
        End of replies to WHO command.
    +/
    RPL_ENDOFWHO = 315,
    
    /++
        Reply to NAMES command.
    +/
    RPL_NAMREPLY = 353,
    
    /++
        End of replies to NAMES command.
    +/
    RPL_ENDOFNAMES = 366,
    
    /++
        Reply to LINKS command.
    +/
    RPL_LINKS = 364,
    
    /++
        End of replies to LINKS command.
    +/
    RPL_ENDOFLINKS = 365,
    
    /++
        A single listing of a ban mask for a channel.
    +/
    RPL_BANLIST = 367,
    
    /++
        End of RPL_BANLIST replies.
    +/
    RPL_ENDOFBANLIST = 368,
    
    /++
        Reply to INFO command.
    +/
    RPL_INFO = 371,
    
    /++
        End of replies to INFO command.
    +/
    RPL_ENDOFINFO = 374,
    
    /++
        Sent at the start of MOTD transmission.
    +/
    RPL_MOTDSTART = 375,
    
    /++
        A line of the MOTD.
    +/
    RPL_MOTD = 372,
    
    /++
        End of the MOTD.
    +/
    RPL_ENDOFMOTD = 376,
    
    /++
        Reply to a successful OPER command.
    +/
    RPL_YOUREOPER = 381,
    
    /++
        Reply to a successful REHASH command.
    +/
    RPL_REHASHING = 382,
    
    /++
        Reply received upon successfully registering as a service.
    +/
    RPL_YOURESERVICE = 383,
    
    /++
        Reply to TIME command.
    +/
    RPL_TIME = 391,
    
    /++
        Start of replies to USERS command.
    +/
    RPL_USERSSTART = 392,
    
    /++
        Reply to USERS command.
    +/
    RPL_USERS = 393,
    
    /++
        End of replies to USERS command.
    +/
    RPL_ENDOFUSERS = 394,
    
    /++
        Reply to USERS if there are no users.
    +/
    RPL_NOUSERS = 395,
    
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
    
    /++
        Reply to TRACE command from each server along the route to the specified server.
    +/
    RPL_TRACELINK = 200,
    
    /++
        Reply to TRACE command indicating a server which has not yet been connected to.
    +/
    RPL_TRACECONNECTING = 201,
    
    /++
        Reply to TRACE command indicating a server which is still completing the server-to-server handshake.
    +/
    RPL_TRACEHANDSHAKE = 202,
    
    /++
        Reply to TRACE command indicating a server which is in an unknown state.
    +/
    RPL_TRACEUNKNOWN = 203,
    
    /++
        Reply to TRACE command upon a user, indicates that the specified user is an operator.
    +/
    RPL_TRACEOPERATOR = 204,
    
    /++
        Reply to TRACE command upon a user.
    +/
    RPL_TRACEUSER = 205,
    
    /++
        Reply to TRACE command upon a server, with details about the specified server.
    +/
    RPL_TRACESERVER = 206,
    
    /++
        Reply to TRACE command upon a user, indicates that the specified user is a service.
    +/
    RPL_TRACESERVICE = 207,
    
    /++
        Reply to TRACE command, indicates a connection of some sort which does not fit any of the other RPL_TRACE* replies.
    +/
    RPL_TRACENEWTYPE = 208,
    
    /++
        Reply to TRACE command. Unknown meaning.
    +/
    RPL_TRACECLASS = 209,
    
    /++
        Reply to TRACE command. Unknown meaning.
    +/
    RPL_TRACELOG = 261,
    
    /++
        End of replies to TRACE command.
    +/
    RPL_TRACEEND = 262,
    
    /++
        Reply to STATS command with information about the specified server's links.
    +/
    RPL_STATSLINKINFO = 211,
    
    /++
        Reply to STATS command with information about the specified server's commands.
    +/
    RPL_STATSCOMMANDS = 212,
    
    /++
        End of replies to STATS command.
    +/
    RPL_ENDOFSTATS = 219,
    
    /++
        Reply to STATS command with information about the specified server's uptime.
    +/
    RPL_STATSUPTIME = 242,
    
    /++
        Reply to STATS command listing the specified server's C-lines.
    +/
    RPL_STATSCLINE = 213,
    
    /++
        Reply to STATS command listing the specified server's N-lines.
    +/
    RPL_STATSNLINE = 214,
    
    /++
        Reply to STATS command listing the specified server's I-lines.
    +/
    RPL_STATSILINE = 215,
    
    /++
        Reply to STATS command listing the specified server's K-lines.
    +/
    RPL_STATSKLINE = 216,
    
    /++
        Reply to STATS command listing the specified server's Y-lines.
    +/
    RPL_STATSYLINE = 218,
    
    /++
        Reply to STATS command listing the specified server's L-lines.
    +/
    RPL_STATSLLINE = 241,
    
    /++
        Reply to STATS command listing the specified server's O-lines.
    +/
    RPL_STATSOLINE = 243,
    
    /++
        Reply to STATS command listing the specified server's H-lines.
    +/
    RPL_STATSHLINE = 244,
    
    /++
        Reply to MODE command on a user, listing their modes.
    +/
    RPL_UMODEIS = 221,
    
    /++
        Reply to LUSERS command specifying the number of users logged in across the network.
    +/
    RPL_LUSERCLIENT = 251,
    
    /++
        Reply to LUSERS command specifying the number of operators logged in across the network.
    +/
    RPL_LUSEROP = 252,
    
    /++
        Reply to LUSERS command specifying the number of unknown connections.
    +/
    RPL_LUSERUNKNOWN = 253,
    
    /++
        Reply to LUSERS command specifying the number of channels across the network.
    +/
    RPL_LUSERCHANNELS = 254,
    
    /++
        Reply to LUSERS command specifying the number of users and links on the local server.
    +/
    RPL_LUSERME = 255,
    
    /++
        Start of reply to ADMIN command.
    +/
    RPL_ADMINME = 256,
    
    /++
        Reply to ADMIN command, first line.
    +/
    RPL_ADMINLOC1 = 257,
    
    /++
        Reply to ADMIN command, second line.
    +/
    RPL_ADMINLOC2 = 258,
    
    /++
        Reply to ADMIN command, third and final line, typically listing the server administrator's email.
    +/
    RPL_ADMINEMAIL = 259,
    
    /++
        Reply to a command which was dropped, requesting the client to try the command again.
    +/
    RPL_TRYAGAIN = 263,
    
    /++
        Reply to a command on a user when that user does not exist.
    +/
    ERR_NOSUCHNICK = 401,
    
    /++
        Reply to a command on a server when that server does not exist.
    +/
    ERR_NOSUCHSERVER = 402,
    
    /++
        Reply to a command on a channel when that channel does not exist.
    +/
    ERR_NOSUCHCHANNEL = 403,
    
    /++
        Reply to a PRIVMSG command on a channel when the message cannot be sent because the user lacks permissions.
    +/
    ERR_CANNOTSENDTOCHAN = 404,
    
    /++
        Reply to JOIN command when the user has already joined too many channels.
    +/
    ERR_TOOMANYCHANNELS = 405,
    
    /++
        Reply to WHOWAS command indicating there is no history for the given nick.
    +/
    ERR_WASNOSUCHNICK = 406,
    
    /++
        Reply to a command where the given targets are ambiguous.
    +/
    ERR_TOOMANYTARGETS = 407,
    
    /++
        Reply to a SQUERY command on a service which does not exist.
    +/
    ERR_NOSUCHSERVICE = 408,
    
    /++
        Reply to a PING or PONG command which is missing the originator parameter.
    +/
    ERR_NOORIGIN = 409,
    
    /++
        Reply to a command which expects a recipient but was given none.
    +/
    ERR_NORECIPIENT = 411,
    
    /++
        Reply to a command which expects a message body but was given none.
    +/
    ERR_NOTEXTTOSEND = 412,
    
    /++
        Reply when sending a message to a mask but no top-level domain is given for the mask.
    +/
    ERR_NOTOPLEVEL = 413,
    
    /++
        Reply when sending a message to a mask but a wildcard is given for the mask's top-level domain.
    +/
    ERR_WILDTOPLEVEL = 414,
    
    /++
        Reply when sending a message to a mask but the mask is invalid.
    +/
    ERR_BADMASK = 415,
    
    /++
        Reply to a command which does not exist.
    +/
    ERR_UNKNOWNCOMMAND = 421,
    
    /++
        Sent when the server does not have a MOTD.
    +/
    ERR_NOMOTD = 422,
    
    /++
        Reply to ADMIN command when there is no administrator information available.
    +/
    ERR_NOADMININFO = 423,
    
    /++
        Sent when a command fails due to a file operation error.
    +/
    ERR_FILEERROR = 424,
    
    /++
        Reply to NICK command when no nick is given.
    +/
    ERR_NONICKNAMEGIVEN = 431,
    
    /++
        Reply to NICK command when the new nickname is invalid.
    +/
    ERR_ERRONEUSNICKNAME = 432,
    
    /++
        Reply to NICK command when the given nickname is already in use.
    +/
    ERR_NICKNAMEINUSE = 433,
    
    /++
        Sent when a nickname collision is detected, presumably after recovery from a netsplit.
    +/
    ERR_NICKCOLLISION = 436,
}
