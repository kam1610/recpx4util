#!/usr/bin/env ruby

require("socket");
require(__dir__ + "/rectvlib.rb");
require("open3");

CMD_RECPX4    = " recpx4 " +
                "--b25 --strip --udp " +
                "--addr __ADDR__ " +
                "--port __PORT__ " +
                "--device /dev/px4-DTV__DEVNUM__ " +
                " __CHNUM__ " +
                " - /dev/null ";
intflag        =         false;
servSock       =           nil;
tcpServer      =           nil;
recpxPid= 0;

## trap ####################################################
trap :INT do
  if(servSock != nil)
    # servSock.close();
  end
  if(tcpServer != nil)
    # tcpServer.close();
  end
  exit(0);
end

## main ####################################################
tcpServer= TCPServer.new("0.0.0.0", RECTV::TCPSERVER_PORT);

while(true)
  tcvBuf  = "";
  servSock= tcpServer.accept();

  ret= IO.select([servSock], nil, nil, RECTV::TIMEOUT);

  if(ret)
    cmd= servSock.gets().strip().split(",");
    p(cmd);
    p(cmd[0]);

    case(cmd[0])
    when(RECTV::CMD_GETSCHEDULE)
      printf("cmd: CMD_GETSCHEDULE\n");
      servSock.write(`crontab -l` + "\n");
      servSock.close();

    when(RECTV::CMD_GETPS)
      printf("cmd: CMD_GETPS\n");
      servSock.write(`ps -Ao pid,cmd | grep recpx4` + "\n");
      servSock.close();

    when(RECTV::CMD_TUNE) # TUNE,port,devnum
      printf("cmd: TUNE\n");
      #p servSock.peeraddr[3];
      #printf("----\n");

      tunecmd= CMD_RECPX4;
      tunecmd= tunecmd.gsub("__ADDR__", servSock.peeraddr[3].to_s);
      tunecmd= tunecmd.gsub("__PORT__", cmd[3]);

      tunecmd= tunecmd.gsub("__DEVNUM__", cmd[1]);
      tunecmd= tunecmd.gsub("__CHNUM__",   cmd[2]);


      print(tunecmd + "\n");

      #myStdIn,myStdOut,myStdErr,myThr= Open3.popen3(tunecmd);
      recpxPid= spawn( tunecmd );
      printf("tuning...\n");
      # recpxPid= myStdOut.pid;
      printf("pid=%d\n", recpxPid);

      servSock.write( recpxPid.to_s + "\n" );
      servSock.close();

    when(RECTV::CMD_STOP)
      printf("cmd: STOP\n");
      if( recpxPid > 0 ) 
        killcmd= "kill -INT #{recpxPid.to_s}";
        printf( killcmd + "\n" );
        print(`#{killcmd}`);
        servSock.write("STOPPED\n");
        recpxPid= 0;
      else
        servSock.write("there is no stopped process\n");
      end
      servSock.close();
    end

  else
    printf("...waiting...\n");
  end
end



