require("time");

## compareCrontab ############################################
def compareCrontabParse(a)
  if( a[0]    == nil ||
      a[0][0] == nil || # blank line
      a[0][0] == "#" || # comment line
      a[0]    == "*" ||
      a[1]    == "*" ||
      a[2]    == "*" ||
      a[3]    == "*" ||
      a[4]    != "*")
    aTime= Time.parse("9999/12/31 00:00");
  else
    aTime= Time.parse("#{a[3]}/#{a[2]} #{a[1]}:#{a[0]}");
  end

  if( aTime.month < Time.now.month )
    aTime= Time.new( aTime.year+1,
                     aTime.month, aTime.day, aTime.hour,
                     aTime.min,   aTime.sec);
  end

  return aTime;
end

def compareCrontab(a,b)
  a= a.strip().split(" ");
  b= b.strip().split(" ");

  a= compareCrontabParse(a);
  b= compareCrontabParse(b);

  if( a == b )
    return 0;
  elsif ( a > b )
    return 1;
  else
    return -1;
  end
end
