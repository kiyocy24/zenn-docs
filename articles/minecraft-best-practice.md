---
title: "Minecraftマルチのベストプラクティス"
emoji: "🦔"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: [minecraft, docker]
published: false
---

# 運用まで考えたらDocker使う一択
Minecraftのマルチサーバをかれこれ4年ほど運用していますが、個人的なベストプラクティスが出たので紹介します\
Minecraftサーバの立て方はありふれてますが、自分の建て方とは節々違ったので書きました

前提としてDocker周りの知識が必要ですが、運用の楽さが段違いになります\
最近のサーバエンジニアには必須スキルといっても過言ではないので、勉強するという意味でもおすすめです

対応できるのはJava版ですが、同様の手法でBedrock版のサーバも立てられるはずです

## 前提
- Minecraft Java版のマルチサーバ
- Minecraftのマルチサーバの知識がある程度ある
- docker, docker-compose の開発環境
- dockerの簡単な操作ができる
  - docker ps
  - docker exec
- サーバ環境
  - Dockerが起動できるのであれば何でもいい
  - ローカルPC, EC2, GCE, VPS, etc...

# Dockerでサーバを立てる
Java版のマルチサーバにもBukkitやForgeなどいくつか種類がありますが、ここではSpigot版を例に進めます\
他のサーバでももちろん対応可能です（ここがDocker管理の良いところ）

Dockerを完全理解に理解している人はDocker Hubから見たほうが早いです

https://hub.docker.com/r/itzg/minecraft-server

https://github.com/itzg/docker-minecraft-server

立てたいMinecraftのバージョンによって指定するJavaのバージョンが微妙に異なるので、最新の1.18.2を例にします\
必須項目だけだと実用に耐えないので、私のおすすめの設定も載せておきます

```docker-compose.yml
version: '3.8'
  mc:
    container_name: minecraft
    image: itzg/minecraft-server:java17
    ports:
      - 25565:25565
    restart: always
    volumes:
      - data:/data
    environment:
      TYPE: SPIGOT
      VERSION: 1.18.2
      EULA: "true"
      
      # ここから下のenvironmentはなくてもOK
      MEMORY: 1000M
      TZ: Asia/Tokyo
      OVERRIDE_SERVER_PROPERTIES: "true"
      OPS: mc_account_name
      WHITELIST: mc_account_1,mc_account2,mc_account3
      MAX_WORLD_SIZE: 2048
      SPAWN_PROTECTION: 32
      SERVER_NAME: Your server name
      MOTD: Dockerサーバです
  volumes:
    data: {}
```

mcというのがサーバ本体のserviceでdataというvolumeを持っています\
起動ごとにデータがリセットされるのは不味いので、volumesでdataという名前をつけてます\
Minecraftのデフォルトポートは25565なのでホストのポートに結びつけて開放します

環境編の必須項目としてサーバのタイプとバージョン、EULAの同意があります。EULAは同意しないとサーバを起動できないので必須です

他で追加してある私の推奨項目についての詳細は以下の通りです\
他の設定値については[こちら](https://github.com/itzg/docker-minecraft-server#server-configuration) に詳しく記載されています

| 環境変数                   | 値                                   | 説明                                                         |
| -------------------------- | ------------------------------------ | ------------------------------------------------------------ |
| MEMORY                     | 1000M or  1GB 以上                   | Minecraftサーバが使用するメモリ<br />足りないとメモリ不足エラーになるので、最低でも1GBは必須 |
| TZ                         | Asia/Tokyo                           | ログの時間が分かりづらくなるのでタイムゾーンを指定           |
| OVERRIDE_SERVER_PROPERTIES | true                                 | docker-compose.ymlで指定した値をserverpropertyに上書きする<br />ゲーム内で設定するよりdocker側で設定したほうが管理が楽になる |
| OPS                        | op権限をつけたいMinecraft名          | ゲーム内で最強の権限をつけるユーザーを指定<br />コンソールから全て入力したいのであれば不要 |
| WHITELIST                  | ログインできるMinecraftアカウント名  | ホワイトリスト管理のサーバでは必須<br />カンマ区切りで複数ユーザーを指定できる |
| MAX_WORLD_SIZE             | ワールドのサイズ                     | サーバのディスク容量には上限があるので要設定<br />足りなくなったら増やせばいい |
| SPAWN_PROTECTION           | 任意の値                             | スポーン地点からのブロック保護範囲<br />スポーン周辺を荒らされると困るので設定する。身内だけなら0で良い |
| SERVER_NAME                | 接続するときに表示されるサーバ名     | サーバ名がデフォルトのままだと他のサーバと区別がつきづらいので設定 |
| MOTD                       | 接続するときに表示されるサーバの説明 | フレーバーテキストなのでなくても良いがあったほうが雰囲気出る |

## 起動する 
ファイルの準備ができたら起動してみます

```shell
# docker-compose.ymlがある場所で叩く
docker-compose up -d

# 起動ログを確認して問題ないか確認
docker logs mc -f
```

起動できたら接続してみます
ローカルの場合は接続先を`localhost`にリモートの場合はIPアドレスかDNS名を入力しましょう
ログインできたら成功です

## rcon-cli

# [Option] 本番と開発で設定を変える

# [Option] プラグインを追加する

# [Option] Dynmapを追加する

# [Option] 自動バックアップを追加する

# 参考
- https://github.com/itzg/docker-minecraft-server