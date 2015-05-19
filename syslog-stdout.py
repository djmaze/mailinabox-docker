#!/usr/bin/python
import sys
import socket
import re
import thread
import time
import datetime
import os

bufsiz=2048


LOG_PRIMASK = 0x07
PRIMASK = { 
0 : "emerg", 
1 : "alert",
2 : "crit",
3 : "err",
4 : "warning",
5 : "notice",
6 : "info",
7 : "debug"
}

FACILITYMASK = {
      0  : "kern",
      1  : "user",
      2  : "mail",
      3  : "daemon",
      4  : "auth",
      5  : "syslog",
      6  : "lpr",
      7  : "news",
      8  : "uucp",
      9  : "cron",
      10 : "authpriv",
      11 : "ftp",
      12 : "ntp",
      13 : "security",
      14 : "console",
      15 : "mark",
      16 : "local0",
      17 : "local1",
      18 : "local2",
      19 : "local3",
      20 : "local4",
      21 : "local5",
      22 : "local6",
      23 : "local7",
}

def bit2string(number):
    try: 
        return "%s.%s"%(FACILITYMASK[number>>3] , PRIMASK[number & LOG_PRIMASK])
    except: 
        return "unknown.unknown"

class SyslogListener(object):        
    def datagramReceived(self,data):
        """strip priority tag"""
        if data[2] == ">":
            pri=bit2string(int(data[1]))
            msg=data[3:]
        elif data[3] == ">":
            pri=bit2string(int(data[1:3]))
            msg=data[4:]
        else:
            pri=None
            msg=data
        msg=msg.strip()
        print "%s:%s"%(pri,msg)
    
    def listen(self):
        try:
            os.remove('/dev/log')
        except:
            pass
        try:
            sock = socket.socket( socket.AF_UNIX, socket.SOCK_DGRAM )
            sock.bind("/dev/log")
            self.sock=sock
            
        except:
            print "Socket error: (%s) %s" % ( sys.exc_info()[1][0], sys.exc_info()[1][1] )
            sys.exit(1)

        while 1:
            try:
                data,addr=sock.recvfrom(bufsiz)
                self.datagramReceived(data)
            except KeyboardInterrupt:
                self.shutdown()
                return
            except socket.error:
                pass
            
    def shutdown(self):
        try:
            self.sock.close()
        except:
            pass
        
        try:
            os.remove('/dev/log')
        except:
            pass

if __name__=='__main__':
    #disable output buffer
    sys.stdout = os.fdopen(sys.stdout.fileno(), 'w', 0)
    lst = SyslogListener()
    lst.listen()
    