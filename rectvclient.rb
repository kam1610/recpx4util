#!/usr/bin/env ruby

require("socket");
require(__dir__ + "/rectvlib.rb");

## printUsage ##############################################
def printUsage()
  printf( "usage: \n"  +
          "   1: rectvvlc.rb #{RECTV::CMD_GETSCHEDULE} host \n" +
          "   2: rectvvlc.rb #{RECTV::CMD_GETPS      } host \n" +
          "   3: rectvvlc.rb #{RECTV::CMD_TUNE       } host dev\# ch port \n" +
          "   4: rectvvlc.rb #{RECTV::CMD_STOP       } host pid \n" );
end

## arglenChk ###############################################
def arglenChk(l)
  if( ARGV.length <= l )
    printUsage();
    exit(0);
  end
end

## sendCommand #############################################
def sendCommand(h, c)
  timeoutDur = 4;

  sock = TCPSocket.open(h, RECTV::TCPSERVER_PORT);
  sock.write(c + "\n");

  iosel= IO.select([sock], nil, nil, timeoutDur);
  if( iosel == nil)
    printf("timeout!\n");
  else
    print( sock.read() );
    sock.close();
    printf("--------\n");
  end
end

## main ####################################################
arglenChk(0);

case( ARGV[0] )

when (RECTV::CMD_GETSCHEDULE) then
  arglenChk(1);
  sendCommand(ARGV[1], RECTV::CMD_GETSCHEDULE);

when RECTV::CMD_GETPS then
  arglenChk(1);
  sendCommand(ARGV[1], RECTV::CMD_GETPS);

when RECTV::CMD_TUNE then
  arglenChk(4);
  sendCommand(ARGV[1],
              RECTV::CMD_TUNE + ",#{ARGV[2]},#{ARGV[3]},#{ARGV[4]}\n");

when RECTV::CMD_STOP then
  arglenChk(2);
  sendCommand(ARGV[1], RECTV::CMD_STOP);

else
  printUsage();

end
