#!/bin/zsh
echo "Xin chào anh Quân"

gemini() {
  local prompt='Luôn đưa ra command nếu có thể để tôi sẽ chạy.'

  if (( $# > 0 )); then
    prompt+=" $*"
  fi

  agy -p --dangerously-skip-permissions "$prompt"
}

import_vscode_extensions() {
	sh /Users/quandn/quandn/import_compat.sh
}

# Hàm helper dùng chung: tạo tên nhánh (theo timestamp nếu không truyền)
_nb_gen_branch_name() {
  local branch_name="$1"
  if [ -z "$branch_name" ]; then
    local timestamp=$(date +"%y%m%d%H%M")
    branch_name="quandn/$timestamp"
  fi
  echo "$branch_name"
}

# nb: chỉ in ra lệnh tạo nhánh, không tự thực thi
nb() {
  local branch_name=$(_nb_gen_branch_name "$1")

  fetch

  printf '%s\n' "git checkout -b $branch_name origin/master"
  printf '%s\n' "git push --set-upstream origin $branch_name"
}

# nbs: tạo nhánh và switch luôn sang nhánh đó (thực thi thật)
nbs() {
  local branch_name=$(_nb_gen_branch_name "$1")

  fetch

  git checkout -b "$branch_name" origin/master
  git push --set-upstream origin "$branch_name"
  printf '%s\n' "git push --set-upstream origin $branch_name"
}

fetch() {
  git fetch --all
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

retailimportdb() {
    importdb --db=db_retail --file="$1"
    importsql --db=db_retail --file="/Users/quandn/quandn/mask-update-retail.sql"
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
  local message="$1"
  if [ -z "$message" ]; then
    local timestamp=$(date +"%y%m%d%H%M")
    message="Auto stash at $(date +"%Y-%m-%d %H:%M:%S")"
  fi
  git stash push -um "$message"
  echo "✅ Đã stash tất cả thay đổi với message: $message"
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

retailDBExport() {
  local timestamp=$(date +%Y%m%d_%H%M%S)
  local sql_filename="db_retail_${timestamp}.sql"
  local zip_filename="db_retail_${timestamp}.zip"
  local sql_path="/tmp/${sql_filename}"
  local zip_path=~/Downloads/"${zip_filename}"

  echo "📦 Đang export database db_retail..."
  mysqldump -u root -proot db_retail > "$sql_path" 2>/dev/null

  if [ $? -ne 0 ]; then
    echo "❌ Export database thất bại!"
    rm -f "$sql_path"
    return 1
  fi

  echo "🗜️ Đang nén file zip..."
  zip -j "$zip_path" "$sql_path" > /dev/null

  if [ $? -eq 0 ]; then
    echo "✅ Export & nén thành công: $zip_path"
    rm -f "$sql_path"
    open ~/Downloads/
  else
    echo "❌ Nén zip thất bại!"
    rm -f "$sql_path"
    return 1
  fi
}

ticDBExport() {
  local timestamp=$(date +%Y%m%d_%H%M%S)
  local sql_filename="db_tic_${timestamp}.sql"
  local zip_filename="db_tic_${timestamp}.zip"
  local sql_path="/tmp/${sql_filename}"
  local zip_path=~/Downloads/"${zip_filename}"

  echo "📦 Đang export database db_tic (bỏ qua active_logs)..."
  MYSQL_PWD=root mysqldump -u root \
    --single-transaction \
    --set-gtid-purged=OFF \
    --routines \
    --triggers \
    --events \
    --ignore-table=db_tic.active_logs \
    db_tic > "$sql_path"

  if [ $? -ne 0 ]; then
    echo "❌ Export database thất bại. Kiểm tra quyền truy cập MySQL và database db_tic."
    rm -f "$sql_path"
    return 1
  fi

  echo "🗜️ Đang nén file zip..."
  if zip -j "$zip_path" "$sql_path" > /dev/null; then
    echo "✅ Export & nén thành công: $zip_path"
    rm -f "$sql_path"
    open ~/Downloads/
  else
    echo "❌ Nén zip thất bại!"
    rm -f "$sql_path"
    return 1
  fi
}

ssh_tic() {
  ssh quandn@27.71.27.163 -p 22 -i ~/.ssh/id_ed25519_ticvietnam
}

ssh_retail() {
  ssh sgtretail@27.71.27.197 -p 22
}

ssh_api_retail() {
  ssh sgtapi@27.71.27.197 -p 22
}

create_pr() {
  local branch_name=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
  local full_link="https://github.com/truongtc/tic/pull/new/$branch_name";
  echo $full_link;
  open $full_link;
}
