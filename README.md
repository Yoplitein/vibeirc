#vibeirc
An IRC module for vibe.d

##Documentation
The code is documented via ddoc comments. There is also online documentation available [here](http://yoplitein.github.io/vibeirc/).

##A simple example
```D
import std.stdio;

import vibeirc;

class Bot: IRCConnection
{
    this()
    {
        nickname = "vibeirc";
    }
    
    override void signed_on()
    {
        join("#test");
    }
    
    override void privmsg(Message message)
    {
        if(message.receiver == nickname || message.isCTCP)
            return;
        
        writefln(
            "[%s] <%s> %s",
            message.receiver,
            message.sender.nickname,
            message.message
        );
    }
}

Bot bot;

static this()
{
    bot = irc_connect!Bot(
        ConnectionParameters(
            "localhost",
            6667
        )
    );
}
```

##License
vibeirc is available under the terms of the BSD 2-clause license. See [LICENSE](LICENSE) for details.

##Contributing
Pull requests and issue reports are welcome!
