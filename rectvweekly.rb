#!/usr/bin/ruby

require("time");

if(ARGV.length != 7)
  printf("usage  : rectvweekly.rb <startdate> <ch> <duration> <dstdir> <prefix> <from#> <to#>\n");
  printf("example: $ rectvweekly.rb \"02/18 22:30\" 27 30 /dev/shm/ mikochi_ 5 12\n");
  printf("       nhk-general        27 \n");
  printf("       nhk-etv            26 \n");
  printf("       nihon tv     (ntv) 25 \n");
  printf("       tokyo housou (tbs) 22 \n");
  printf("       fuji tv      (cx ) 21 \n");
  printf("       tv asahi     (anb) 24 \n");
  printf("       tv tokyo     (tx ) 23 \n");
  printf("       MX                 16 \n");
  printf("       tv kanagawa  (tvk) 18 \n");
  printf("       chiba tv           30 \n");
  printf("       tv saitama         32 \n");
  printf("       housou daigaku     28 \n");
  exit 0;
end

sDTime= Time.parse(ARGV[0]);
if( sDTime.month < Time.now.month )
  sDTime= Time.new( sDTime.year+1,
                    sDTime.month, sDTime.day, sDTime.hour,
                    sDTime.min,   sDTime.sec);
end

fromIx= ARGV[5].to_i;
toIx  = ARGV[6].to_i;

fromIx.upto(toIx){|ix|
  cmd= format("rectvcron.rb \"%02d/%02d %02d:%02d\" %02d %02d %s/%s%02d.mp4",
              sDTime.month,  sDTime.day,
              sDTime.hour,   sDTime.min,
              ARGV[1].to_i, # ch
              ARGV[2].to_i, # duration
              ARGV[3],      # dstdir
              ARGV[4],      # prefix
              ix            # ix
             );
  printf("%s\n", cmd);
  print(`#{cmd}`);
  sDTime+= 7 * 24 * 60 * 60;

}
