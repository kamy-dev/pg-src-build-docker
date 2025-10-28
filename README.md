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

$ docker run -d --name postgres -p 5432:5432 -v pg_data:/pgsql -v pg_wal:/wal pg-src-plpy:dev

# 本番 (ソースコード反映、DB本番利用)
$ docker build -t pg-src-plpy:prod --target prod .

$ docker run -d --name postgres -p 5432:5432 -v pg_data:/pgsql -v pg_wal:/wal pg-src-plpy:prod
```

### 2. Podman の場合

```bash
# 開発 (ソースコード修正、DB機能検証)
$ podman build -t pg-src-plpy:dev --target dev .

$ podman run -d --name postgres -p 5432:5432 -v pg_data:/pgsql -v pg_wal:/wal pg-src-plpy:dev

# 本番 (ソースコード反映、DB本番利用)
$ podman build -t pg-src-plpy:prod --target prod .

$ podman run -d --name postgres -p 5432:5432 -v pg_data:/pgsql -v pg_wal:/wal pg-src-plpy:prod
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
