#!/bin/zsh
echo "Xin chào anh Quân"

alias exportPermission='sh /Users/quandn/quandn/export_permission.sh'
alias gendb='sh /Users/quandn/quandn/gen_db.sh'
alias genretaildb='sh /Users/quandn/quandn/genretaildb.sh'
alias cls='sh /Users/quandn/quandn/web/tic/clear_cache.sh'
alias lg='sh /Users/quandn/quandn/web/tic/log_laravel.sh'
alias fix_bogo='ioreg -l -w 0 | grep SecureInput'
alias off='sh /Users/quandn/quandn/turnoff.sh'
alias openapp='sh /Users/quandn/quandn/open_app.sh'
alias quitapp='sh /Users/quandn/quandn/quit_app.sh'
alias pp='php artisan'
alias claude-start="claude --dangerously-skip-permissions"
alias export-role-permissions='mysqldump -u root -psecret tic_role roles_permissions > ~/Downloads/roles_permissions_$(date +\%F_%H-%M-%S).sql'
alias importsql='sh /Users/quandn/quandn/importsql.sh'
alias importdb='sh /Users/quandn/quandn/importdb.sh'
alias pint='./vendor/bin/pint'
alias reload='source ~/.zshrc'


copypath() {
	realpath "$1" | pbcopy | osascript -e 'display notification "Đã copy đường dẫn thành công" with title "Terminal"'
}

copyToClipboard() {
	echo -n "$1" | pbcopy
}

# Git commit với template
gitcommit() {
	if [ -z "$1" ]; then
		echo "❌ Vui lòng nhập nội dung commit!"
		echo "📝 Cách dùng: gitcommit \"nội dung commit\""
		return 1
	fi

	local commit_message="$1"
	local current_time=$(date "+%Y-%m-%d %H:%M:%S")
	local current_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)

	if [ -z "$current_branch" ]; then
		echo "❌ Không phải git repository!"
		return 1
	fi

	local full_message="${commit_message}

++++++++
Creator: QUANDN
Commit Time: ${current_time}
Branch: ${current_branch}"

	git commit -m "$full_message"
	git pull origin "$current_branch"
	git push origin "$current_branch"
}

login_mysql() {
	mysql -u root -proot
}

# Thêm method tạo copilot suggestion : copilot -p "message";
ghs() {
	# kiểm tra nếu message trống thì hiển thị hướng dẫn sử dụng
	if [ -z "$1" ]; then
		echo "Cách dùng: ghs \"Nội dung tin nhắn\""
		return 1
	fi
	copilot -p "$@"
}

roleExport() {
	local env_file="/Users/quandn/quandn/web/tic/.env"
	local current_db=$(grep '^DB_DATABASE=' "$env_file" | cut -d '=' -f2- | tr -d '\r')
	local db_user=$(grep '^DB_USERNAME=' "$env_file" | cut -d '=' -f2- | tr -d '\r')
	local db_password=$(grep '^DB_PASSWORD=' "$env_file" | cut -d '=' -f2- | tr -d '\r')
	local file_path=~/Downloads/permissions_$(date +%Y%m%d_%H%M%S).sql

	if [ -z "$current_db" ]; then
		echo "❌ Không đọc được DB_DATABASE từ $env_file"
		return 1
	fi

	cd /Users/quandn/quandn/web/tic || return 1

	# Hàm cleanup - luôn được gọi khi exit
	cleanup() {
		sed -i '' "s/DB_DATABASE=.*/DB_DATABASE=$current_db/" .env
	}

	# Đặt trap để gọi cleanup khi exit hoặc error
	trap "sed -i '' 's/DB_DATABASE=.*/DB_DATABASE=$current_db/' .env" EXIT

	# Đổi sang database tic_role
	sed -i '' "s/DB_DATABASE=.*/DB_DATABASE=tic_role/" .env

	# Chạy migrate
	php artisan migrate:fresh --seed || return 1

	# Dump database với username và password từ .env
	mysqldump -u "$db_user" -p"$db_password" --set-gtid-purged=OFF tic_role permissions roles_permissions >"$file_path" || return 1

	open ~/Downloads/
	echo "✅ Hoàn thành! Database đã được rollback về $current_db"
}

export ANTHROPIC_BASE_URL="http://192.168.88.252:8008"
export ANTHROPIC_AUTH_TOKEN="sk-NriZfRKywApQsREWh7L8fA"
export ANTHROPIC_MODEL="claude-sonnet-4-6"
export CLAUDE_CODE_AUTO_COMPACT_WINDOW="160000"
export API_TIMEOUT_MS="3600000"
export CLAUDE_CODE_MAX_OUTPUT_TOKENS="8192"
export CLAUDE_CODE_DISABLE_ADAPTIVE_THINKING="1"

stashnow() {
	git stash push -um "Auto stash at $(date +"%Y-%m-%d %H:%M:%S")"
	echo "✅ Đã stash tất cả thay đổi với message: Auto stash at $(date +"%Y-%m-%d %H:%M:%S")"
}

code1() {
	export ANTHROPIC_BASE_URL="http://192.168.88.252:8008"
	export ANTHROPIC_AUTH_TOKEN="sk-NriZfRKywApQsREWh7L8fA"
	export ANTHROPIC_MODEL="claude-sonnet-4-6"
	export CLAUDE_CODE_AUTO_COMPACT_WINDOW="160000"
	export API_TIMEOUT_MS="3600000"
	export CLAUDE_CODE_MAX_OUTPUT_TOKENS="8192"
	export CLAUDE_CODE_DISABLE_ADAPTIVE_THINKING="1"
	export ENABLE_TOOL_SEARCH="true"
	# export CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS=1
	# export DISABLE_PROMPT_CACHING=1

	echo "Đang khởi động Claude..."
	claude "$@"
}

code2() {
	echo "Đang khởi động openCode..."
	opencode "$@"
}

getlog() {
	local currentYearMonth=$(date +"%Y/%m")
	local currentTime=$(date +"%Y-%m-%d")
	local relativePath="storage/logs/$currentYearMonth/laravel-$currentTime.log"
	# auto copy path
	copyToClipboard "tail -f $relativePath"
	echo "Đã copy lệnh: tail -f $relativePath vào clipboard. Bạn có thể dán và chạy lệnh này để theo dõi log."
}

tic() {
	cd /Users/quandn/quandn/web/tic
}

retailmini() {
    cd /Users/quandn/quandn/web/retailmini
}

tic-clear() {
	cd /Users/quandn/quandn/web/tic || return 1
	php artisan optimize:clear
}
master() {
	git checkout master
	git pull origin master
	git push origin master
}

merge() {
    # tham số đầu tiên là bắt buộc là tên branch cần merge vào master
    if [ -z "$1" ]; then
        echo "❌ Vui lòng nhập tên branch cần merge vào master!"
        echo "📝 Cách dùng: merge <tên_branch>"
    else
        git checkout master
        git pull origin master
        git merge "$1"
        git push origin master
    fi
}

# ---- GITHUB COPILOT CLI - REMOTE LLM CONFIGURATION ----
# URL endpoint của máy tính kia (phải có hậu tố /v1 nếu theo chuẩn OpenAI)
export COPILOT_PROVIDER_BASE_URL="http://192.168.88.252:8008/v1"

# Kiểu nhà cung cấp (giữ nguyên là openai nếu server kia trả về chuẩn OpenAI API)
export COPILOT_PROVIDER_TYPE="openai"

# Tên mô hình chính xác đang chạy trên máy tính kia (ví dụ: qwen2.5-coder:7b, deepseek-coder, ...)
export COPILOT_MODEL="claude-sonnet-4-6"

# Điền API Key chính xác của server kia vào đây
export COPILOT_PROVIDER_API_KEY="sk-NriZfRKywApQsREWh7L8fA"

# Bật chế độ offline để Copilot không kiểm tra bản quyền Cloud của GitHub
export COPILOT_OFFLINE=true

# curl http://192.168.88.252:8008/v1/models \
#   -H "Authorization: Bearer sk-NriZfRKywApQsREWh7L8fA"


download() {
    cd ~/Downloads || return 1
}

quandn() {
    cd ~/quandn || return 1
}

retail() {
    cd ~/quandn/web/retail || return 1
}

retailAPI() {
    cd ~/quandn/web/retail-api || return 1
}

runcode() {
    cd ~/quandn/web/tic || return 1
    code .

    cd ~/quandn/web/retail || return 1
    code .

    cd ~/quandn/web/retail-api || return 1
    code .

    cd ~/quandn/web/retailmini || return 1
    code .
}
