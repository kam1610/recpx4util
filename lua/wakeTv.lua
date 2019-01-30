-- "axtractAudio" -- VLC Extension --
-- $HOME/.local/share/vlc/lua/extensions/wakeTv.lua
-- %APPDATA%\vlc\lua\extensions

stream_port= "8888"
tv_host    = "haruka"
tv_host_mac= "00:00:00:00:00:00"
client_cmd = "rectvclient.rb "
-- sudo firewall-cmd --add-port=8888/udp
-- sudo firewall-cmd --add-port=8889/udp

-- descriptor ----------------------------------------------
function descriptor()
	return {title = "wake tv";
	capabilities = { "input-listener" }
	}
end

-- activate ------------------------------------------------
function activate()
   local d = vlc.dialog( "wake tv" )
            d:add_label     ( "port", 1, 1, 1, 1)
   portNum= d:add_text_input( "8888", 2, 1, 1, 1)
            d:add_label     ( "dev",  3, 1, 1, 1)
   devNum = d:add_text_input( "3",    4, 1, 1, 1)
   chList = d:add_dropdown  (         1, 2, 4, 1)
            chList:add_value("nhk-general          27")
            chList:add_value("nhk-etv              26")
            chList:add_value("nihon tv     (ntv)   25")
            chList:add_value("tokyo housou (tbs)   22")
            chList:add_value("fuji tv      (cx )   21")
            chList:add_value("tv asahi     (anb)   24")
            chList:add_value("tv tokyo     (tx )   23")
            chList:add_value("MX                   16")
            chList:add_value("tv kanagawa  (tvk)   18")
            chList:add_value("chiba tv             30")
            chList:add_value("tv saitama           32")
            chList:add_value("housou daigaku       28")
            chList:set_text ("nhk-general          27")
            d:add_button    ("ether-wake",   haruka_wake,  1, 3, 4, 1)
            d:add_button    ("get schedule", get_schedule, 1, 4, 1, 1)
            d:add_button    ("get ps",       get_ps,       2, 4, 1, 1)
            d:add_button    ("tune",         my_tune,      3, 4, 1, 1)
            d:add_button    ("stop",         my_stop,      4, 4, 1, 1)
   console= d:add_html      ( "..",   1, 5, 5, 300)
   d:show()
end

-- haruka_wake ---------------------------------------------
function haruka_wake()
   vlc.msg.info(":::: haruka_wake ::::")
   local handle = assert( io.popen("sudo /sbin/ether-wake "..
                                      tv_host_mac, "r") )
   vlc.msg.info("     a wake command is sended")
   handle.close()
end

-- get_schedule -------------------------------------------
function get_schedule()
   vlc.msg.info(":::: get_schedule ::::")
   local handle = assert( io.popen(client_cmd ..
                                   " GETSCHEDULE "..
                                      tv_host, "r") )
   local body= "";
   local cnt= 0;
   for line in handle:lines() do
      body= body .. "<br>\n" .. line
      cnt= cnt + 1;
      if( cnt > 20 )then
         break;
      end
   end
   vlc.msg.info( body )
   console:set_text( body )
   handle:close()
end

-- get_ps --------------------------------------------------
function get_ps()
   vlc.msg.info(":::: get_schedule ::::")
   local handle = assert( io.popen(client_cmd ..
                                   " GETPS "..
                                      tv_host, "r") )
   local body= "";
   for line in handle:lines() do
      body= body .. "<br>\n" .. line
   end
   vlc.msg.info( body )
   console:set_text( body )
   handle:close()
end

-- my_tune -------------------------------------------------
function my_tune()
   vlc.msg.info(":::: get_schedule ::::")
   local ch= string.match(chList:get_text(), " (%d+)$")
   if (ch) then
      vlc.msg.info( "ch:" .. ch )
   else
      ch= "27"
      vlc.msg.info( "ch is set to default 27(nhk)")
   end
   local cmd=
      client_cmd ..
      "TUNE " ..
      tv_host .. " " ..
      devNum:get_text() .. " " ..
      ch .. " " ..
      portNum:get_text()
   vlc.msg.info( cmd )

   local handle = assert( io.popen(cmd, "r") )
   local body= "";
   for line in handle:lines() do
      body= body .. "<br>\n" .. line
   end
   vlc.msg.info( body )
   console:set_text( body )
   vlc.msg.info( "handle was closed.." )
   -- net.stat( "udp://@8888" )


   vlc.msg.info( "adding playlist table" )
   mytable = {}
   mytable.path = "udp://@:" .. portNum:get_text()
   vlc.playlist.add({mytable})

   vlc.msg.info( "starting..." )

   handle:close()
end

-- my_stop -------------------------------------------------
function my_stop()
   vlc.msg.info(":::: stop ::::")
   local handle = assert( io.popen(client_cmd ..
                                   " STOP "..
                                      tv_host .. " 0", "r") )
   local body= "";
   for line in handle:lines() do
      body= body .. "<br>\n" .. line
   end
   vlc.msg.info( body )
   console:set_text( body )
   handle:close()
end


