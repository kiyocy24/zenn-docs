---
title: "短期運用のMinecraftサーバをGCP上に爆速構築する"
emoji: "🐕"
type: "tech"
topics: ["Minecraft", "GCP","Terraform", "Docker"]
published: true
---

:::message
GCPで構築するなら、多分これが1番早いです
:::

# Minecraftサーバを建てるの結構面倒じゃないですか？
5年ほどマイクラサーバを運用しているのですが、最近数日しか使わないサーバが必要になりました
1つのマイクラサーバに複数のワールドを配置することもできるのですが、バージョンを変えたり、別のModを入れたりすると競合したりと面倒です

どうせ数日で使い切るならと新しく建てることにしたのですが、これが結構面倒だったので無駄な要素を削ぎ落とし、最低限の手順で作成してみました

## 前提となる環境と前提知識
- GCP
  - デプロイ用のGCPプロジェクト
  - VMインスタンスの作成ができる
- Terraform
  - terraformコマンドが打てる
- Docker
  - 若干、使うが最悪、知識なしでもOK
- MinecraftのバージョンはSpigotを使用
  - 統合版やModサーバも対応可能

少々インフラとコンテナの知識が必要ですが、長い運用を想定してないので付け焼き刃でいけます

# 構築手順
構築用の設定をTerraformに書き起こしてGithubに上げました
これをデプロイするだけです

```shell
# Clone
git clone https://github.com/kiyocy24/gcp-mc-server.git

# Move to directory
cd gcp-mc-server/terraform

# Setup terraform.tfvars
echo 'project = "<GCP_PROJECT>"' > terraform.tfvars

# Deploy
terraform plan
terraform apply # IP Address is output
```

https://github.com/kiyocy24/gcp-mc-server

あらかじめ作成したGCPプロジェクトに対してデプロイしてください
`apply`まで成功すると、IPアドレスが表示されるのでMinecraftサーバにログインできれば成功です


# 解説
これだけだと設定変えたり、問題が起こったときの調査に困るので軽く解説します

## Terraform
Infrastructure as Code というやつでインフラをコードで管理するためのツールです
tfファイルにマイクラサーバの設置を含むインフラの設定を記述し、`terraform apply`というコマンドでデプロイしています

`terraform.tfvars`でデプロイするGCPプロジェクトを指定します
`variable.tf`で定義されている変数を上書きするためのファイルです

`compute.tf`でサーバのマシンスペックや開放ポート、マイクラサーバの設定します
主に見る必要があるのは`compute.tf`です

https://github.com/kiyocy24/gcp-mc-server/blob/main/terraform/compute.tf

Minecraftサーバ本体はDocker上で動いていて、それを定義しているのが`gce-container`です
VMインスタンス上にコンテナを立ち上げるためのモジュールになります

`google_compute_instance`ではマシンタイプやディスクタイプとその容量、
`google_compute_firewall`では開放ポートを指定しています

## itzg/docker-minecraft-server
`gce-container.container`でコンテナのイメージと渡す環境変数を指定しています
使うイメージは[itzg/docker-minecraft-server](https://github.com/itzg/docker-minecraft-server)です
イメージの使い方は本家を見るのが正確ですが、よく使うであろう環境変数を紹介します

| 変数名              | 説明                                                                                                                             |
|------------------|--------------------------------------------------------------------------------------------------------------------------------|
| TYPE             | サーバのタイプ（SPIGOT, BUKKIT, FORGE, etc...）                                                                                         |
| VERSION          | マインクラフトバージョン（ex. 1.19.3）                                                                                                       |
| EULA             | 規約の同意、trueを渡さないと起動できない                                                                                                         |
| MEMORY           | サーバに割り当てるメモリ                                                                                                                   |
| MAX_WORLD_SIZE   | ワールドサイズ                                                                                                                        |
| SPAWN_PROTECTION | スポーン地点の保護範囲                                                                                                                    |
| OPS              | OP権限を持つユーザー（ex. mc_id1,mc_id2,mc_id3）                                                                                          |
| WHITELIST        | ホワイトリストのユーザー、環境変数を渡さない場合は誰でもログイン可                                                                                              |
| SPIGET_RESOURCES | プラグインの番号（詳細は[こちら](https://github.com/itzg/docker-minecraft-server#auto-downloading-spigotmcbukkitpapermc-plugins-with-spiget)） |

最低限TYPE, VERSION, EULAの3つがあれば問題なく遊べるようになります

https://github.com/itzg/docker-minecraft-server


## ログ
MinecraftサーバのログはCloud Loggingに出力されます
コンテナの起動ログも含まれているのでフィルタリングすればより見やすくなるはずです

## コンテナに接続
マイクラサーバが起動しているコンテナに接続する場合は、VMインスタンスに接続してDockerコマンドを実行します
マイクラサーバ以外にCloud Loggingにログを送るためのコンテナが起動していることが分かります

```shell
# コンテナ一覧
$ docker ps
CONTAINER ID   IMAGE                                                       COMMAND                  CREATED      STATUS                PORTS     NAMES
ba76c10957c6   itzg/minecraft-server                                       "/start"                 3 days ago   Up 3 days (healthy)             klt--zjvy
4c6d8f87d9eb   gcr.io/stackdriver-agents/stackdriver-logging-agent:1.9.8   "/entrypoint.sh /usr…"   3 days ago   Up 3 days                       stackdriver-logging-agent

# bashで接続
kanazawa@mc-server ~ $ docker exec -it ba76c10957c6 bash
```

コンテナのカレントディレクトリにはワールドデータやサーバの設定ファイルがあります
マイクラサーバを1度でも建てたことがあれば見慣れたものだと思います

https://github.com/itzg/docker-minecraft-server#data-directory

# [補足] 長期運用を想定するなら
これらは環境構築を最速で実施するためのものなので、長期運用には向いていない設定がいくつかあります
数日や数週間程度であれば十分ですが、1年以上の運用を考えるなら以下も考慮する必要があります

- エフェメラルなIPなので固定IPにしつつ、DNSも検討
- データの定期的なバックアップ
- ローカルでの開発環境構築（デバッグ等のため）

これらについてはいずれまた記事にしようと思っています

# まとめ
GCPで簡単にマイクラサーバを建てる方法を紹介しました
Terraformモジュールやコンテナを使うことによって煩わしいJavaのインストールやポート開放などの手間が省けるようになりました
ただ、短期的な運用をする前提での構築なので長期運用を想定するなら、また別の方法を模索する必要があります

VPSではすでにマイクラ用に提供しているものもあるので、GCPにこだわらなければぶっちゃけそっちの方が楽で最速かもしれません
インフラの勉強も兼ねてのサーバ運用であれば、TerraformやDockerの練習にもなるので興味があればやってみてほしいです

いずれ長期運用を想定した記事も書きますのでそのときはまた
