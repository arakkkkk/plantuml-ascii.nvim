-- lua/plantuml_ascii.lua
local M = {}

-- PlantUMLのパスを設定
-- local plantuml_jar_path = vim.fn.expand("<sfile>:p:h") .. "/../plantuml-1.2024.8.jar" -- ここを実際のパスに置き換えてください
-- print(plantuml_jar_path)
local file_path = debug.getinfo(1, "S").source
local dir_path = file_path:match("^@(.*)/")
local plantuml_jar_path = dir_path .. "/../plantuml-1.2024.8.jar" -- ここを実際のパスに置き換えてください

-- 一時ファイルの設定
local temp_input_file = "/tmp/plantuml.puml"
local temp_output_file = "/tmp/plantuml.utxt"

local function get_cursor_block()
	local bufnr = vim.api.nvim_get_current_buf()
	local current_line = vim.fn.line(".")
	local start_line, end_line = current_line, current_line

	-- 上方向にコードブロックの開始を探す
	while start_line > 1 do
		local current_line_text = vim.api.nvim_buf_get_lines(bufnr, start_line - 1, start_line, false)[1]
		if current_line_text:match("^```plantuml$") then
			break
		end
		start_line = start_line - 1
	end

	-- 下方向にコードブロックの終了を探す
	while end_line < vim.api.nvim_buf_line_count(bufnr) do
		local current_line_text = vim.api.nvim_buf_get_lines(bufnr, end_line, end_line + 1, false)[1]
		if current_line_text:match("^```$") then
			break
		end
		end_line = end_line + 1
	end

	-- コードブロックを取得
	local lines = vim.api.nvim_buf_get_lines(bufnr, start_line, end_line, false)

	return lines
end

-- PlantUMLコマンドを実行
local function run_plantuml(input_path)
	-- -tutxt オプションでASCIIモードに指定
	local cmd = string.format("java -jar %s -charset UTF-8 -tutxt %s", plantuml_jar_path, input_path)
	print(cmd)
	local handle = io.popen(cmd)
	local result = handle:read("*a")
	handle:close()
	return result
end

-- バッファを分割ウィンドウで表示
local function open_split_buffer(ascii_art)
	-- 新しいバッファを作成
	local buf = vim.api.nvim_create_buf(false, true)

	-- バッファにASCIIアートを書き込む
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(ascii_art, "\n"))

	-- 読み取り専用とnomodelineを設定
	vim.api.nvim_buf_set_option(buf, "modifiable", false)
	vim.api.nvim_buf_set_option(buf, "readonly", true)
	vim.api.nvim_buf_set_option(buf, "modeline", false)

	-- 垂直分割ウィンドウでバッファを開く
	vim.api.nvim_command("vsplit")
	vim.api.nvim_win_set_buf(0, buf)
end

-- NeovimにASCIIアートを表示
function M.show_ascii_art()
	-- 現在のバッファの内容を取得
	local lines = get_cursor_block()
	local content = table.concat(lines, "\n")

	-- PlantUMLコードを一時ファイルに保存
	local input_file = io.open(temp_input_file, "w")
	input_file:write(content)
	input_file:close()

	-- PlantUMLでASCIIアートを生成
	run_plantuml(temp_input_file, temp_output_file)

	-- ASCIIアートを読み込み
	local output_file = io.open(temp_output_file, "r")
	local ascii_art = output_file:read("*a")
	output_file:close()

	-- 分割ウィンドウでASCIIアートを表示
	open_split_buffer(ascii_art)
end

-- コマンド登録
function M.setup()
	vim.api.nvim_create_user_command("PlantUMLAscii", M.show_ascii_art, {})
end

return M
