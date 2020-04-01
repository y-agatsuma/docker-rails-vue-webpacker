# 前提
 - docker / docker-compose をインストール済

# 実行後のディレクトリ構成
```
【app_name】
  ∟ Dockerfile
  ∟ docker-compose.yml
  ∟ src
    ∟ [rails new で生成されたファイル群]
```

# 使い方
## 1. 任意のディレクトリを作成

```bash
ex.
$ mkdir sample_app
$ cd sample_app
```

## 2. shellを配置して実行
```bash
$ bash docker-rails-vue.sh
```

## 3. 起動確認して接続
```bash
$ docker-compose ps
     Name                   Command             State                 Ports              
------------------------------------------------------------------------------------------
sample_app_db_1    docker-entrypoint.sh mysqld   Up      0.0.0.0:3306->3306/tcp, 33060/tcp
sample_app_web_1   rails s -p 3000 -b 0.0.0.0    Up      0.0.0.0:3000->3000/tcp
```
http://localhost:3000/に接続
