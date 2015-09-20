#vibeirc
An IRC module for vibe.d

##Documentation
The code is documented via ddoc comments. There is also online documentation available [here](http://yoplitein.github.io/vibeirc/).

##Examples
###Simple
```D
import std.stdio;

import vibeirc;

shared static this()
{
    auto bot = new IRCClient;
    
    void onLogin()
    {
        bot.join("#test");
    }

    void onMessage(Message message)
    {
        if(message.target == bot.nickname || message.isCTCP)
            return;
        
        writefln(
            "[%s] <%s> %s",
            message.target,
            message.sender.nickname,
            message.message
        );
    }
    
    bot.onLogin = &onLogin;
    bot.onMessage = &onMessage;
    
    bot.connect("irc.example.net", 6667);
}
```

###More complete example
See [example/](blob/master/example/src/app.d)

##License
vibeirc is available under the terms of the BSD 2-clause license. See [LICENSE](LICENSE) for details.

##Contributing
Pull requests and issue reports are welcome!
