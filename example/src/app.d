/++
    Connects to a server and joins all specified channels.
    Logs all events that occur to stdout.
+/
module app;

import core.time;
import std.functional;
import std.stdio;
import std.string;

import vibe.core.args;
import vibe.core.core;

import vibeirc;

IRCClient bot;
string host;
string nickname;
string password;
string[] channels;
ushort port = 6667;

shared static this()
{
    host = readRequiredOption!string(
        "a|host",
        "Host to connect to",
    );
    nickname = readRequiredOption!string(
        "n|nickname",
        "Nickname to use",
    );
    
    //readOption can't handle string[] :(
    auto channelList = readRequiredOption!string(
        "c|channels",
        "List of channels to join, separated by commas",
    );
    channels = channelList.split(",");
    
    readOption(
        "p|port",
        &port,
        "Port to connect on",
    );
    readOption(
        "P|password",
        &password,
        "Password to use when connecting, if any",
    );
    
    bot = new IRCClient;
    bot.nickname = nickname;
    bot.onDisconnect = toDelegate(&onDisconnect);
    bot.onLogin = toDelegate(&onLogin);
    bot.onMessage = toDelegate(&onMessage);
    bot.onNotice = toDelegate(&onMessage);
    bot.onUserJoin = toDelegate(&onUserJoin);
    bot.onUserPart = toDelegate(&onUserPart);
    bot.onUserQuit = toDelegate(&onUserQuit);
    bot.onUserRename = toDelegate(&onUserRename);
    bot.onUserKick = toDelegate(&onUserKick);
    
    //defer connection until after arguments have been processed
    runTask(toDelegate(&connect));
}

void connect()
{
    bot.connect(host, port, password);
}

void onDisconnect(string reason)
{
    writeln("Disconnected: ", reason);
    sleep(10.seconds);
    writeln("Attempting to reconnect");
    connect;
}

void onLogin()
{
    writeln("Logged in");
    
    foreach(channel; channels)
    {
        writeln("Joining ", channel);
        bot.join(channel);
    }
}

void onMessage(Message message)
{
    string bodyFormat;
    string bracketText;
    
    if(message.isCTCP)
    {
        if(message.ctcpCommand != "ACTION")
        {
            writefln(
                "%s sends CTCP %s",
                message.sender.nickname,
                message.ctcpCommand,
            );
            
            return;
        }
        
        bodyFormat = "* %s %s";
    }
    else
        bodyFormat = "<%s> %s";
    
    if(message.target == bot.nickname)
        bracketText = "Private Message";
    else
        bracketText = message.target;
    
    writefln(
        "[%s] " ~ bodyFormat,
        bracketText,
        message.sender.nickname,
        message.message,
    );
}

void onUserJoin(User user, string channel)
{
    writefln(
        "[%s] %s joined",
        channel,
        user.nickname,
    );
}

void onUserPart(User user, string channel, string reason)
{
    writefln(
        "[%s] %s left (%s)",
        channel,
        user.nickname,
        reason == null ? "No reason given" : reason,
    );
}

void onUserQuit(User user, string reason)
{
    writefln(
        "%s quit (%s)",
        user.nickname,
        reason == null ? "No reason given" : reason,
    );
}

void onUserRename(User user, string newNick)
{
    writefln(
        "%s is now known as %s",
        user.nickname,
        newNick,
    );
}

void onUserKick(User kicker, string kickee, string channel, string reason)
{
    writefln(
        "[%s] %s kicked %s (%s)",
        channel,
        kicker.nickname,
        kickee,
        reason == null ? "No reason given" : reason,
    );
}
