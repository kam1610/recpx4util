#!/usr/bin/ruby
# Wait until the latest scheduled time
# --
# please add the line below to sudoers file
#   %kosame ALL=NOPASSWD: /usr/sbin/rtcwake

logpath= "/dev/shm/rectvsleep.log";

require("time");
require(__dir__ + "/rectvlib.rb");

# get current crontab
crontab= `crontab -l`;

curTime= Time.now();
minDiff= Time.parse("9999/12/31 00:00") - curTime;
minTime= Time.parse("9999/12/31 00:00");

crontab= crontab.lines.each{|c|
  c= c.strip().split(" ");
  aTime= compareCrontabParse(c);
  diffTime= aTime - curTime;
  if( (diffTime < minDiff) &&
      (diffTime > 0) )
    minDiff= diffTime;
    minTime= aTime;
  end
}

minTime-= 60*5;

cmd= format("sudo rtcwake -m mem -t #{minTime.to_i} ");
print("wake up scheduled: " + minTime.to_s);
`echo #{cmd} | tee -a #{logpath}`;
`#{cmd}`
