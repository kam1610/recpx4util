-- "axtractAudio" -- VLC Extension --
-- $HOME/.local/share/vlc/lua/extensions/extractAudio.lua
-- %APPDATA%\vlc\lua\extensions

-- descriptor ----------------------------------------------
function descriptor()
	return {title = "extract audio";
	capabilities = { "input-listener" }
	}
end

-- activate ------------------------------------------------
function activate()
	input     = vlc.object.input();
  crop_times=  ""

	local d = vlc.dialog( "extract audio" )
	d:add_button("set start time", fetch_start_time, 1, 1, 1, 1 )
  startTimeBox= d:add_text_input( "00:00.000",     2, 1, 1, 1 )

  d:add_button("set end time"  , fetch_end_time,   3, 1, 1, 1 )
  endTimeBox  = d:add_text_input( "00:00.000",     4, 1, 1, 1 )

  d:add_button("generate mp3 cmd",      conv_mp3, 5, 1, 1, 1 )
  d:add_button("generate m4a(aac) cmd", conv_m4a, 6, 1, 1, 1 )

  d:add_button("run mp3",      run_mp3,  7, 1, 1, 1 )
  d:add_button("run m4a(aac)", run_m4a,  8, 1, 1, 1 )

  cmd1     = d:add_text_input( "ffmpeg ", 1, 4, 40, 2 )
  cmd2     = d:add_text_input( "ffmpeg ", 1, 6, 40, 2 )
	d:show()
end

-- deactivate ----------------------------------------------
function deactivate()
end

-- close ---------------------------------------------------
function close()
   vlc.deactivate()
end

-- urldecode -----------------------------------------------
function urldecode(str)
   local str = string.gsub(str, "%%([0-9a-fA-F][0-9a-fA-F])",
                     function (c) return string.char(tonumber("0x" .. c)) end)
         str = string.gsub (str, "\n", "\r\n")
   return str
end

-- format_timestamp ----------------------------------------
function format_timestamp(a)
   return string.format("%02d:%02d.%03d",
                        a/1000000/60,
                        (a/1000000)%60,
                        (a/1000)%1000)
end

-- fetch_timestamp -----------------------------------------
function fetch_timestamp()
   return format_timestamp( math.floor(vlc.var.get(input,"time") ) )
end

-- fetch_start_time ----------------------------------------
function fetch_start_time()
   startTimeBox:set_text( fetch_timestamp() )
end
-- fetch_end_time ------------------------------------------
function fetch_end_time()
   endTimeBox:set_text( fetch_timestamp() )
end

-- decode_formatted_time -----------------------------------
function decode_formatted_time(s)
   local hh,mm,subm= string.match( s , "(%d%d):(%d%d)%.(%d%d%d)" )
   return (hh * 60 * 1000000) + (mm * 1000000) + (subm * 1000)
end

-- get_diff_time -------------------------------------------
function get_diff_time()
   return
      decode_formatted_time( endTimeBox:get_text() ) -
      decode_formatted_time( startTimeBox:get_text() )
end

-- ffmpeg_command ------------------------------------------
ffmpeg_command=
   "ffmpeg "..
   " -y "..
   " -ss __start_time__"..
   " -i  \"__in_file__\" "..
   " -t  __duration__ "..
   " -acodec __codecspec__ "..
   " -vn"..
   " \"__out_file__\" "
-- format_ffmpeg_command -----------------------------------
function format_ffmpeg_command(ss, in_file, duration, codecspec, out_file)
   local command= string.gsub(ffmpeg_command, "__start_time__", ss)
         command= string.gsub(command,        "__in_file__",    in_file)
         command= string.gsub(command,        "__duration__",   duration)
         command= string.gsub(command,        "__codecspec__",  codecspec)
         command= string.gsub(command,        "__out_file__",   out_file)
   return command
end

-- get_item_uri --------------------------------------------
function get_item_uri()
   local item  = vlc.input.item()
   local uri   = item:uri()
         uri   = string.gsub(uri, '^file://', '')
         uri   = urldecode(uri)
   return uri
end

-- conv_mp3 ------------------------------------------------
function conv_mp3()
   local uri     = get_item_uri()
   local dsturi  = string.gsub(uri, "^(.*)(%.[^.]*)$", "%1.mp3")
   local difftime= format_timestamp( get_diff_time() )

   local command=
      format_ffmpeg_command( startTimeBox:get_text(),
                             uri,
                             difftime,
                             " libmp3lame -ac 2 -ar 44100 -ab 256k -vn -f mp3 ",
                             dsturi )

   cmd1:set_text( command )
end

-- conv_m4a ------------------------------------------------
function conv_m4a()
   local uri     = get_item_uri()
   local dsturi  = string.gsub(uri, "^(.*)(%.[^.]*)$", "%1.m4a")
   local difftime= format_timestamp( get_diff_time() )

   local command=
      format_ffmpeg_command( startTimeBox:get_text(),
                             uri,
                             difftime,
                             " copy ",
                             dsturi )

   cmd2:set_text( command )
end

analyze_command=
   "ffmpeg "..
   "-i \"__in_file__\" "..
   "-filter:a volumedetect -f null /dev/null 2>&1"
normalize_command=
   "ffmpeg "..
   " -y "..
   "-i \"__in_file__\" "..
   " -ab 256k "..
   "-filter:a \"volume=__volume__dB\" "..
   "\"__out_file__\""
-- normalize_volume ----------------------------------------
function normalize_volume()
   vlc.msg.info(":::: normalize_volume ::::")

   local uri      = get_item_uri()
   local srcuri   = string.gsub(uri, "^(.*)(%.[^.]*)$", "%1.m4a")
   local dsturi   = string.gsub(uri, "^(.*)(%.[^.]*)$", "%1.norm.m4a")
   local volume   = 0.0
   local command_a=
      string.gsub(analyze_command,   "__in_file__",  srcuri)
   local command_b=
      string.gsub(normalize_command, "__in_file__",  srcuri)
         command_b=
      string.gsub(command_b,         "__out_file__", dsturi)
   local handle = assert( io.popen(command_a, "r") )

   for line in handle:lines() do
      -- vlc.msg.info("    -> "..line)
      volume= string.match(line, "max_volume: (-?%d+%.%d) dB")
      if( volume )then
         vlc.msg.info("    volume is "..volume)
         handle:close()
         break
      end
   end
   volume= tonumber(volume)
   vlc.msg.info("    analyze volume...");
   if( volume < 0 )then
      vlc.msg.info("__1")
      volume= volume * -1
      volume= volume - 0.1
      vlc.msg.info("    volume: "..tostring(volume))

      command_b= string.gsub(command_b, "__volume__", tostring(volume))
      vlc.msg.info("    normalize command: "..command_b)
      handle= assert( io.popen(command_b, "r") )
      handle:close()
      vlc.msg.info("    finished.")
   else
      vlc.msg.info("__2")
      vlc.msg.info("    volume: "..tostring(volume))
   end
end

-- run_mp3 -------------------------------------------------
function run_mp3()
   local handle = io.popen(cmd1:get_text(), "r")
   local content= handle:read("*all")

   for line in content:lines() do
      print("::::".. line );
   end

   handle:close()
end

-- run_m4a -------------------------------------------------
function run_m4a()
   vlc.msg.info(":::: run_m4a ::::")
   local handle = assert( io.popen(cmd2:get_text(), "r") )
   vlc.msg.info("     the command is executed")
   handle:close()
   vlc.msg.info("     this handle is closed")
   
   normalize_volume()
end

