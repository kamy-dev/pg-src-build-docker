# PostgreSQL ソースコードビルド Dockerfile

PostgreSQL のソースコードからビルドする軽量な本番環境を提供します。  
マルチステージビルドにより、コンパイル済みバイナリのみを含む最適化されたイメージを構築します。

## 概要

この Dockerfile は以下の機能を提供します：

-   PostgreSQL の最新ソースコードからのマルチステージビルド
-   PL/Python 拡張のサポート
-   軽量な本番環境用コンテナ（ビルドツール含まない）
-   自動データベース初期化機能

詳細は以下の記事をご覧ください。

> ### <u>[Qiita: PostgreSQL のソースコードからのビルド完全ガイド](https://qiita.com/Kamy-dev/items/55d5d7db44ac4216d573)</u>

## 使用方法

### 1. Docker の場合

```bash
# 開発 (ソースコード修正、DB機能検証)
$ docker build -t pg-src-plpy:dev --target dev .

$ docker run -d --name postgres -p 5432:5432 \
  -v pg_data:/pgsql -v pg_wal:/wal \
  pg-src-plpy:dev

# 本番 (ソースコード反映、DB本番利用)
$ docker build -t pg-src-plpy:prod --target prod .

$ docker run -d --name postgres -p 5432:5432 \
  -v pg_data:/pgsql -v pg_wal:/wal \
  pg-src-plpy:prod
```

### 2. Podman の場合

```bash
# 開発 (ソースコード修正、DB機能検証)
$ podman build -t pg-src-plpy:dev --target dev .

$ podman run -d --name postgres -p 5432:5432 -v pg_data:/pgsql -v pg_wal:/wal pg-src-plpy:dev

# 本番 (ソースコード反映、DB本番利用)
$ podman build -t pg-src-plpy:prod --target prod .

$ podman run -d --name postgres -p 5432:5432 \
  -v pg_data:/pgsql -v pg_wal:/wal \
  pg-src-plpy:prod
```

### 3. 接続方法

コンテナ起動後、以下の方法で PostgreSQL に接続できます：

#### Docker の場合

```bash
$ docker exec -it postgres bash

# コンテナ内でpsqlを使用
$ psql -h localhost -p 5432 -U postgres

# または外部から接続 (ローカルにpsqlがインストールされていること)
$ psql -h localhost -p 5432 -U postgres
```

#### Podman の場合

```bash
$ podman exec -it postgres bash

# コンテナ内でpsqlを使用
$ psql -h localhost -p 5432 -U postgres

# または外部から接続 (ローカルにpsqlがインストールされていること)
$ psql -h localhost -p 5432 -U postgres
```

### PL/Python 拡張の有効化と使用例

```sql
-- PL/Python拡張を有効化
CREATE EXTENSION plpython3u;

-- サンプル関数の作成
CREATE FUNCTION pymax(a integer, b integer)
RETURNS integer
AS $$
    if a > b:
        return a
    return b
$$ LANGUAGE plpython3u;

-- 使用例
SELECT pymax(5, 10); -- 結果: 10
```

## マルチステージビルドの詳細

### Stage 1: Development (dev)

-   **ベースイメージ**: Ubuntu 22.04 LTS
-   **用途**: PostgreSQL のソースコードビルド
-   **含まれるもの**: ビルドツール、開発ヘッダー、Git 等
-   **サイズ**: 大（約 2GB+）

### Stage 2: Production (prod) - デフォルト

-   **ベースイメージ**: Ubuntu 22.04-slim
-   **用途**: 本番環境での実行
-   **含まれるもの**: 実行時ライブラリのみ
-   **サイズ**: 小（約 500MB）

## トラブルシューティング

### SSL 証明書エラー (git clone 失敗)

```
fatal: unable to access 'https://git.postgresql.org/git/postgresql.git/':
server certificate verification failed. CAfile: none CRLfile: none
```

**原因**: CA 証明書の検証エラー

**解決策**:

1. **Docker**: システム時刻を確認 (`date`)
2. **ネットワーク**: プロキシ設定やファイアウォールを確認
3. **一時的回避**: HTTP 経由でクローン
    ```bash
    # Dockerfileの修正（緊急時のみ）
    RUN git -c http.sslVerify=false clone https://git.postgresql.org/git/postgresql.git
    ```

### ビルド時間が長い場合

```bash
# 並列ビルドでの高速化
docker build --build-arg MAKEFLAGS="-j$(nproc)" -t pg-src-img:latest .

# Buildkitによる最適化（Docker 18.09+）
DOCKER_BUILDKIT=1 docker build -t pg-src-img:latest .
```

### メモリ不足エラー

```bash
# Dockerのメモリ制限を増加
docker system info | grep -i memory

# WSL2の場合（.wslconfig）
[wsl2]
memory=8GB
processors=4
```
