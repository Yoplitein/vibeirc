module vibeirc.data;

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
