local audio = require "ejoy2dx.Liekkas.audio"
local bgm = require "liekkas.bgm"

local M = {
  is_close = false,
  _cur_playing_file_path = false,
  _cur_loop = false,
}

local function _gen_bgm()
  local cur_file_path = false
  local m = {}

  function m.load(file_path)
    bgm.load(file_path)
    cur_file_path = file_path
  end 

  function m.play(file_path, loop)
    if file_path ~= cur_file_path then
      m.load(file_path)
    end
    bgm.play(loop or false)
  end

  function m.stop()
    bgm.stop()
  end
  return m
end


local function _gen_bgm_soft()
  local music_group = audio:create_group()
  local music_handle = false
  local m = {}
  local cur_file_path = false

  function m.load(file_path)
    if file_path ~= cur_file_path then
      audio:unload(file_path)
    end
    audio:load(file_path)
  end

  function m.play(file_path, loop)
    if file_path ~= cur_file_path then
      m.load(file_path)
    end
    music_handle = music_group:add(file_path, loop)
    music_group:play(music_handle)
  end

  function m.stop()
    if music_handle then
      music_group:stop(music_handle)
    end
  end

  return m
end



local _cur_bg_handle = bgm and _gen_bgm() or _gen_bgm_soft()


function M.load(file_path)
  _cur_bg_handle.load(file_path)
end

function M.play(file_path, loop)
  M._cur_playing_file_path = file_path
  M._cur_loop = loop
  
  if M.is_close then
    return
  end
  _cur_bg_handle.play(file_path, loop)
end


function M.stop()
  _cur_bg_handle.stop()
end


function M.open()
  local file_path = M._cur_playing_file_path
  local loop = M._cur_loop
  M.is_close = false
  if file_path then
    _cur_bg_handle.play(file_path, loop)
  end
end

function M.close()
  _cur_bg_handle.stop()
  M.is_close = true
end


return M
