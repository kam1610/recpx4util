-- "crop-and-concat" -- VLC Extension --
-- $HOME/.local/share/vlc/lua/extensions/cropandcat.lua
-- $HOME/.var/app/org.videolan.VLC/data/vlc/lua/extensions/

function descriptor()
	return {title = "crop and concat";
	capabilities = { "input-listener" }
	}
end

function activate()
	input     = vlc.object.input();
  crop_times=  ""

	local d = vlc.dialog( "crop and concat" )
	d:add_button("get time stamp", fetch_time_dialog , 1, 1, 1, 1)

  croptimes= d:add_text_input( "", 1, 2, 80, 1 )
  cmd      = d:add_text_input( "cropmp4.rb ", 1, 3, 80, 2 )
	d:show()
end

function deactivate()
end

function close()
   vlc.deactivate()
end

function urldecode(str)
   str = string.gsub(str, "%%([0-9a-fA-F][0-9a-fA-F])",
                     function (c) return string.char(tonumber("0x" .. c)) end)
   str = string.gsub (str, "\n", "\r\n")
   return str
end

function fetch_time_dialog()
   timestamp= math.floor(vlc.var.get(input,"time"))
   local min= math.floor(timestamp/1000000/60)
   local sec= math.floor((timestamp/1000000)%60)
   local msec= (timestamp - min*60*1000000 - sec*1000000) / 1000

   print(string.format("timestamp: %f, min: %f, sec: %f, msec: %f", timestamp, min, sec, msec))

   timestamp= string.format("%02d:%02d.%02d", min//1, sec//1, msec//1)
   print( timestamp )
   crop_times= croptimes:get_text().." "..timestamp
   croptimes:set_text( crop_times )

   local item = vlc.input.item()
   local uri  = item:uri()
   uri= string.gsub(uri, '^file://', '')
   uri= urldecode(uri)

   dsturi= string.gsub(uri, "(.*/)(.*)%.mp4", "%2")
   
   cmdtext= "cropmp4.rb "..uri
   cmdtext= cmdtext.." "..croptimes:get_text()
   cmdtext= cmdtext.." ".."/dev/shm/"..dsturi..".crop.mp4"
   print(cmdtext)
   
   cmd:set_text( cmdtext )

   -- os.execute(strCmd)

end
