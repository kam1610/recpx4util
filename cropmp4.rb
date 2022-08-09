#!/home/kosame/.rbenv/shims/ruby

tmpDir     = "/dev/shm/";
tmpPrefix  = "cropmp4_";
tmpListFile= tmpDir + tmpPrefix + "lst";
tmpList    = [];
diffList   = [];
chapter    = ";FFMETADATA1\n";

if( ARGV.length     <  4 ||
    ARGV.length % 2 == 1 )
  printf( "usage: cropmp4.rb <src> <from(mm:ss.ms)> <to(mm:ss.ms)> [<from to pairs>...] <dst>\n" );
  exit(0);
end

srcFile = ARGV[ 0];
dstFile = ARGV[-1];

cmdTemplate= "ffmpeg \\ \n" +
             "  -ss    __fromTime__ \\       \n" +
             "  -i     #{srcFile} \\         \n" +
             "  -t     __diffTime__ \\       \n" +
             "  -c     copy \\               \n" +
#             "  -bsf:a aac_adtstoasc \\      \n" +
             "  -bsf:v h264_mp4toannexb \\   \n" +
             "  -f     mpegts \\             \n" +
             "         __dstFile__ \\        \n";

prevEnd= 0.0;
endTime= 0.0;

1.step((ARGV.length - 2), 2){|ix|
  fromTime= ARGV[ix  ];
  toTime  = ARGV[ix+1];

  fromTime= fromTime.split(/[:.]/)[0].to_i() * 60 +
            fromTime.split(/[:.]/)[1].to_i() +
            fromTime.split(/[:.]/)[2].to_i() / 1000.0;

  toTime  = toTime.split(/[:.]/)[0].to_i() * 60 +
            toTime.split(/[:.]/)[1].to_i() +
            toTime.split(/[:.]/)[2].to_i() / 1000.0;

  diffTime= toTime - fromTime;

  startTime= prevEnd;
  endTime  = startTime + diffTime;

  chapter+= "[CHAPTER]\n" +
            "TIMEBASE=1/1000000\n" +
            "START=#{format("%d", (startTime * 1000000))}\n" +
            "END=#{format("%d", (endTime * 1000000))}\n" +
            "title=#{ix.to_s()}\n";

  prevEnd= endTime;

  tmpFile= tmpDir + tmpPrefix + ix.to_s + ".ts";
  tmpList.push(tmpFile);

  diffList.push(diffTime);

  cmd= cmdTemplate.sub("__fromTime__", format("%.3f", fromTime) );
  cmd= cmd.sub("__diffTime__", format("%.3f", diffTime.to_s) );
  cmd= cmd.sub("__dstFile__",  tmpFile);

  printf( cmd + "\n");
  cmd= cmd.gsub(/[\\\n]/,"");
  printf( "%s\n", `#{cmd}` );

}

open(tmpDir + "chapter.ini", "w"){|f|
  f.write( chapter ); }

# open(tmpListFile, "w"){|f|
#   tmpList.each(){|l|
#     f.write("file '" + l + "'\n");
#   }
# }

#cmd= "ffmpeg -i #{tmpListFile} -c copy -bsf:a aac_adtstoasc #{dstFile}";
#cmd= "ffmpeg -i \"concat:#{tmpList.join("|")}\" -c copy    -bsf:a aac_adtstoasc  #{dstFile}";
cmd= "ffmpeg -i \"concat:#{tmpList.join("|")}\" -i #{tmpDir}chapter.ini -map_metadata 1 -map_chapters 1 -c copy -bsf:a aac_adtstoasc  #{dstFile}";
printf( cmd + "\n");
printf( "%s\n", `#{cmd}` );

tmpList.each(){|i|
  cmd= "rm #{i}"
  printf( cmd + "\n");
  printf( "%s\n", `#{cmd}` );
}

#cmd= "rm #{tmpListFile}";
#printf( cmd + "\n");
#printf( "%s\n", `#{cmd}` );

sum= 0;
diffList.each(){|i|
  sum+= i;
  printf("%02d:%02d ", sum/60, sum%60);
}
printf("\n");
