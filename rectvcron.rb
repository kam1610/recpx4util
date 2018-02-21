#!/usr/bin/ruby

libpath="/home/kosame/src/recpx4/";

require("time");
require(libpath + "./rectvlib.rb");

binpath = "/home/kosame/bin/";
reccmd  = "rectv.sh";
aftercmd= "; sleep 10; /home/kosame/bin/rectvsleep.rb";
cronfile= "/dev/shm/rectvcron"

## main ####################################################
if( ARGV.length != 4)
  printf( "usage: rectvcron.rb <date> <ch> <duration> <dst>\n" );
  printf( "date-> \"01/23 23:00\"\n" );
  exit(0);
end

rsvDTime= Time.parse(ARGV[0]);

if( rsvDTime.month < Time.now.month )
  rsvDTime= Time.new( rsvDTime.year+1,
                      rsvDTime.month, rsvDTime.day, rsvDTime.hour,
                      rsvDTime.min,   rsvDTime.sec);
end

# set 2mins ago
rsvDTime-= 2 * 60;

# add 5mins
duration= (ARGV[2].to_i + 5).to_s;

# get current crontab
crontab= `crontab -l`;

crontabDate= format("%02d %02d %02d %02d * ",
                    rsvDTime.min.to_s, rsvDTime.hour.to_s,
                    rsvDTime.day.to_s, rsvDTime.month.to_s);


# add new entry
crontab += " #{crontabDate}"      +
           " #{binpath}#{reccmd}" +
           " #{ARGV[1]}"          + # ch
           " #{duration}"         + # duration
           " #{ARGV[3]}"          + # dst
           " #{aftercmd}\n";

# sort
crontab= crontab.lines.sort{|a,b|
  compareCrontab(a,b);
}

# export
printf(">>>> export to #{cronfile}..\n");
open( cronfile, "w" ){|f|
  crontab.each(){|l|
    if( l != "\n" )
      f.write( l.chomp() + "\n" );
      printf(l.chomp() + "\n");
    end
  }
}
printf(">>>> applying to cron..\n");
cmd= "crontab #{cronfile}"
printf(cmd + "\n");
printf("%s", `#{cmd}`);
