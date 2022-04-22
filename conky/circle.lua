
require 'cairo'

--------------------------------------------------------------------------------
--                                                                    clock DATA
-- 小时
clock_h = {
  {
    name='time',                   arg='%H',                    max_value=12,
    x=200,                         y=200,
    -- 圆圈半径
    graph_radius=160,
    -- 圆圈边框粗细
    graph_thickness=10,
    -- 圆圈激活色单位弧长, 360/12 = 30, 
    -- thickness 为填充弧长, 不等于单位弧长时, 表现为 间隔效果
    graph_unit_angle=30,           graph_unit_thickness=30,
    -- 圆圈底色
    graph_bg_colour=0xffffff,      graph_bg_alpha=0.0,
    -- 圆圈激活色
    graph_fg_colour=0x64b5f6,      graph_fg_alpha=0.3,
    txt_radius=180,
    txt_weight=1,                  txt_size=32.0,
    txt_fg_colour=0x64b5f6,        txt_fg_alpha=0.6,
  },
}
-- 分
clock_m = {
  {
    name='time',                   arg='%M',                    max_value=60,
    x=200,                         y=200,
    graph_radius=150,
    graph_thickness=8,
    graph_unit_angle=6,            graph_unit_thickness=6,
    graph_bg_colour=0xffffff,      graph_bg_alpha=0.1,
    graph_fg_colour=0x48c9b0,      graph_fg_alpha=0.3,
    txt_radius=136,
    txt_weight=0,                  txt_size=32.0,
    txt_fg_colour=0x48c9b0,        txt_fg_alpha=0.6,
  },
}
-- 秒
clock_s = {
  {
    name='time',                   arg='%S',                    max_value=60,
    x=200,                         y=200,
    graph_radius=140,
    graph_thickness=8,
    graph_unit_angle=6,            graph_unit_thickness=2,
    graph_bg_colour=0xffffff,      graph_bg_alpha=0.0,
    graph_fg_colour=0xffd342,      graph_fg_alpha=0.3,
    txt_radius=114,
    txt_weight=0,                  txt_size=32.0,
    txt_fg_colour=0xffd342,        txt_fg_alpha=0.3,
  },
}

--------------------------------------------------------------------------------
--                                                                    gauge DATA
gauge = {
  {
    name='cpu',                    arg='cpu',                  max_value=100,
    x=80,                          y=740,
    graph_radius=68,
    graph_thickness=16,
    graph_start_angle=180,
    graph_unit_angle=2.7,          graph_unit_thickness=2.7,
    graph_bg_colour=0xffffff,      graph_bg_alpha=0.2,
    graph_fg_colour=0xfc7661,      graph_fg_alpha=0.6,
  },
  {
    name='memperc',                arg='',                      max_value=100,
    x=80,                          y=1080,
    graph_radius=68,
    graph_thickness=16,
    graph_start_angle=180,
    graph_unit_angle=2.7,          graph_unit_thickness=2.7,
    graph_bg_colour=0xffffff,      graph_bg_alpha=0.2,
    graph_fg_colour=0xfc7661,      graph_fg_alpha=0.6,
  },
}

-------------------------------------------------------------------------------
--                                                                 
-- rgb颜色拆解
--
function rgb_to_r_g_b(colour, alpha)
    return ((colour / 0x10000) % 0x100) / 255., ((colour / 0x100) % 0x100) / 255., (colour % 0x100) / 255., alpha
end

-------------------------------------------------------------------------------
--                                                            
-- 度数转弧长计算
--
function angle_to_position(start_angle, current_angle)
    local pos = current_angle + start_angle
    return ( ( pos * (2 * math.pi / 360) ) - (math.pi / 2) )
end

-------------------------------------------------------------------------------
--                                                              
-- 画时钟圆圈
--
function draw_clock_ring(display, data, value)
    local max_value = data['max_value']
    local x, y = data['x'], data['y']
    local graph_radius = data['graph_radius']
    local graph_thickness, graph_unit_thickness = data['graph_thickness'], data['graph_unit_thickness']
    local graph_unit_angle = data['graph_unit_angle']
    local graph_bg_colour, graph_bg_alpha = data['graph_bg_colour'], data['graph_bg_alpha']
    local graph_fg_colour, graph_fg_alpha = data['graph_fg_colour'], data['graph_fg_alpha']

    -- 画圆圈底色
    cairo_arc(display, x, y, graph_radius, 0, 2 * math.pi)
    cairo_set_source_rgba(display, rgb_to_r_g_b(graph_bg_colour, graph_bg_alpha))
    cairo_set_line_width(display, graph_thickness)
    cairo_stroke(display)

    -- 画高亮色
    local val = (value % max_value)
    local i = 1
    while i <= val do
        cairo_arc(display, x, y, graph_radius,(  ((graph_unit_angle * i) - graph_unit_thickness)*(2*math.pi/360)  )-(math.pi/2),((graph_unit_angle * i) * (2*math.pi/360))-(math.pi/2))
        cairo_set_source_rgba(display,rgb_to_r_g_b(graph_fg_colour,graph_fg_alpha))
        cairo_stroke(display)
        i = i + 1
    end
    local angle = (graph_unit_angle * i) - graph_unit_thickness

    -- 画文本
    local txt_radius = data['txt_radius']
    local txt_weight, txt_size = data['txt_weight'], data['txt_size']
    local txt_fg_colour, txt_fg_alpha = data['txt_fg_colour'], data['txt_fg_alpha']
    local movex = txt_radius * (math.cos((angle * 2 * math.pi / 360)-(math.pi/2)))
    local movey = txt_radius * (math.sin((angle * 2 * math.pi / 360)-(math.pi/2)))
    cairo_select_font_face (display, "ubuntu", CAIRO_FONT_SLANT_NORMAL, txt_weight);
    cairo_set_font_size (display, txt_size);
    cairo_set_source_rgba (display, rgb_to_r_g_b(txt_fg_colour, txt_fg_alpha));
    cairo_move_to (display, x + movex - (txt_size / 2), y + movey + 3);
    cairo_show_text (display, value);
    cairo_stroke (display);
end

-------------------------------------------------------------------------------
--                                                              
-- 画资源使用率
--
function draw_gauge_ring(display, data, value)
    local max_value = data['max_value']
    local x, y = data['x'], data['y']
    local graph_radius = data['graph_radius']
    local graph_thickness, graph_unit_thickness = data['graph_thickness'], data['graph_unit_thickness']
    local graph_start_angle = data['graph_start_angle']
    local graph_unit_angle = data['graph_unit_angle']
    local graph_bg_colour, graph_bg_alpha = data['graph_bg_colour'], data['graph_bg_alpha']
    local graph_fg_colour, graph_fg_alpha = data['graph_fg_colour'], data['graph_fg_alpha']
    local graph_end_angle = (max_value * graph_unit_angle) % 360


    cairo_arc(display, x, y, graph_radius, angle_to_position(graph_start_angle, 0), angle_to_position(graph_start_angle, graph_end_angle))
    cairo_set_source_rgba(display, rgb_to_r_g_b(graph_bg_colour, graph_bg_alpha))
    cairo_set_line_width(display, graph_thickness)
    cairo_stroke(display)


    local val = value % (max_value + 1)
    local start_arc = 0
    local stop_arc = 0
    local i = 1
    while i <= val do
        start_arc = (graph_unit_angle * i) - graph_unit_thickness
        stop_arc = (graph_unit_angle * i)
        cairo_arc(display, x, y, graph_radius, angle_to_position(graph_start_angle, start_arc), angle_to_position(graph_start_angle, stop_arc))
        cairo_set_source_rgba(display, rgb_to_r_g_b(graph_fg_colour, graph_fg_alpha))
        cairo_stroke(display)
        i = i + 1
    end
   
end

-------------------------------------------------------------------------------
--                                                               
-- 加载时钟
--
function go_clock_rings(display)
  local function load_clock_rings(display, data)
    local str, value = '', 0
    str = string.format('${%s %s}',data['name'], data['arg'])
    str = conky_parse(str)
    value = tonumber(str)
    draw_clock_ring(display, data, value)
  end
  
  for i in pairs(clock_h) do
    load_clock_rings(display, clock_h[i])
  end
  for i in pairs(clock_m) do
    load_clock_rings(display, clock_m[i])
  end
  for i in pairs(clock_s) do
    load_clock_rings(display, clock_s[i])
  end
end

-------------------------------------------------------------------------------
--                                                               
-- 加载资源使用
--
function go_gauge_rings(display)
  local function load_gauge_rings(display, data)
    local str, value = '', 0
    str = string.format('${%s %s}',data['name'], data['arg'])
    str = conky_parse(str)
    value = tonumber(str)
    draw_gauge_ring(display, data, value)
  end
  
  for i in pairs(gauge) do
    load_gauge_rings(display, gauge[i])
  end
end

-------------------------------------------------------------------------------
--                                                                         
function conky_main()
  if conky_window == nil then 
    return
  end

  local cs = cairo_xlib_surface_create(conky_window.display, conky_window.drawable, conky_window.visual, conky_window.width, conky_window.height)
  local display = cairo_create(cs)

  go_clock_rings(display)
  go_gauge_rings(display)

  
  cairo_surface_destroy(cs)
  cairo_destroy(display)
end

