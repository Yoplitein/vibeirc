///
module vibeirc.data;

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
    string target; ///The destination of the message, either a user or a channel.
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
