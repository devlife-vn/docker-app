#!/bin/zsh
echo "Xin chào anh Quân"

nb() {
  # Tạo tên nhánh theo thời gian: năm tháng ngày giờ phút
  local timestamp=$(date +"%y%m%d%H%M")
  local branch_name="quandn/$timestamp"
  git fetch --all --prune
  printf '%s\n' "git checkout -b $branch_name origin/master"
  printf '%s\n' "git push --set-upstream origin $branch_name"
}

codetic() {
  cd ~/quandn/web/tic || return 1
  code .
}

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
alias export-role-permissions='mysqldump -u root -psecret tic_role roles_permissions > ~/Downloads/roles_permissions_$(date +\%F_%H-%M-%S).sql'
alias importsql='sh /Users/quandn/quandn/importsql.sh'
alias importdb='sh /Users/quandn/quandn/importdb.sh'
alias pint='./vendor/bin/pint'
alias reload='source ~/.zshrc'

ticimportdb() {
    importdb --db=db_tic --file="$1"
}

roleimportdb() {
    importdb --db=db_role --file="$1"
}

retailimportdb() {
    importdb --db=db_retail --file="$1"
    time importsql --db=db_retail --file="/Users/quandn/quandn/mask-update-retail.sql"
}

ticimportsql() {
    importsql --db=db_tic --file="$1"
}

roleimportsql() {
    importsql --db=db_role --file="$1"
}

retailimportsql() {
    importsql --db=db_retail --file="$1"
}

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

stashnow() {
  git stash push -um "Auto stash at $(date +"%Y-%m-%d %H:%M:%S")"
  echo "✅ Đã stash tất cả thay đổi với message: Auto stash at $(date +"%Y-%m-%d %H:%M:%S")"
}

code1() {
  export ANTHROPIC_BASE_URL="https://integrate.api.nvidia.com/v1"
  export ANTHROPIC_AUTH_TOKEN="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"
  export ANTHROPIC_MODEL="z-ai/glm-5.2"
  export CLAUDE_CODE_AUTO_COMPACT_WINDOW="160000"
  export API_TIMEOUT_MS="3600000"
  export CLAUDE_CODE_MAX_OUTPUT_TOKENS="8192"
  export CLAUDE_CODE_DISABLE_ADAPTIVE_THINKING="1"
  export ENABLE_TOOL_SEARCH="true"
  echo "Đang khởi động Claude..."
  claude "$@"
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
  local current_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
  git checkout master
  git pull origin master

  if [ -n "$current_branch" ]; then
    git checkout "$current_branch"
  fi
}

getcodemaster() {
  git merge origin/master
  git push origin "$(git rev-parse --abbrev-ref HEAD 2>/dev/null)"
}

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

formatsh() {
  shfmt -w -i 2 -ci -bn "$@"
}
