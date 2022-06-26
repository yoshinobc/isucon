#!/bin/bash

set -e

sudo chown -R isucon:isucon {homeディレクトリ下のconfigファイルのパス}

# checkout main
git fetch origin
git reset --hard origin/main
git pull origin main

# goビルド
cd {goのパス}
make
cd -

# nginx のログを削除
echo ":: CLEAR LOGS       ====>"
sudo truncate -s 0 -c /var/log/nginx/access.log

# 各種サービスの再起動
echo
echo ":: RESTART SERVICES ====>"
# nginx
sudo cp -r {homeディレクトリ下のconfigファイルのパス}/nginx/* /etc/nginx/
# mysql
sudo cp -r {homeディレクトリ下のconfigファイルのパス}/* /etc/mysql/
sudo systemctl restart nginx

{init.shのパス}/init.sh
sudo mysqladmin flush-logs
sudo systemctl restart mysql
sudo systemctl restart {hoge.golang}
sudo systemctl restart nginx # nginx -s reaload

sleep 5

# ベンチマークの実行
echo
echo ":: BENCHMARK        ====>"
cd {アプリケーション下}
{ベンチマーク実行}

# alp で解析
echo
echo ":: ACCESS LOG       ====>"
sudo cat /var/log/nginx/access.log |  alp ltsv -m "^/items/\d+\.json$,^/users/\d+\.json,^/upload/[0-9a-f]+\.jpg$,^/transactions/\d+\.png$,^/new_items/\d+\.json$" --sort avg -r

# slow query logとnginx logをgit管理
sudo mkdir -p /tmp/log
sudo cp /var/log/mysql/mysql-slow.log /tmp/log/mysql-slow.log
sudo cp /var/log/nginx/access.log /tmp/log/access.log
