# PostgreSQL ソースコードビルド用 Dockerfile

PostgreSQL のソースコードからビルドし、開発・テスト環境を提供します。  
PostgreSQL のオープンソース貢献にも利用できる コンテナ 環境です。

## 概要

この Dockerfile は以下の機能を提供します：

-   PostgreSQL の最新ソースコードからのビルド
-   PL/Python 拡張のサポート
-   開発・テスト用の環境構築

## 使用方法

### 1. Docker の場合

```bash
# Dockerfileを配置したディレクトリに移動
# イメージをビルド
docker build -t pg-src-plpy:latest .

# コンテナを実行（データ永続化あり）
docker run -d -it --name postgres-container -p 5432:5432 -v pg_data:/pgsql -v pg_wal:/wal pg-src-plpy:latest
```

### 2. Podman の場合

```bash
# Dockerfileを配置したディレクトリに移動
# イメージをビルド
podman build -t pg-src-plpy:latest .

# コンテナを実行（データ永続化あり）
podman run -d -it --name postgres-container -p 5432:5432 -v pg_data:/pgsql -v pg_wal:/wal pg-src-plpy:latest
```

### 3. 接続方法

コンテナ起動後、以下の方法で PostgreSQL に接続できます：

#### Docker の場合

```bash
# コンテナ内でpsqlを使用
docker exec -it postgres-container bash
su - postgres
psql

# または外部から接続 (ローカルにpsqlがインストールされていること)
psql -h localhost -p 5432 -U postgres
```

#### Podman の場合

```bash
# コンテナ内でpsqlを使用
podman exec -it postgres-container bash
su - postgres
psql

# または外部から接続 (ローカルにpsqlがインストールされていること)
psql -h localhost -p 5432 -U postgres
```

### PL/Python 拡張の有効化

```sql
CREATE EXTENSION plpython3u;
```

## 開発環境の詳細

-   **ベースイメージ**: Ubuntu 22.04 LTS
-   **PostgreSQL ソース**: 公式 Git リポジトリから Clone
-   **ビルド設定**: OpenSSL、libxml、libxslt、Python 拡張を有効化
-   **データ永続化**: `/pgsql`（データディレクトリ）、`/wal`（WAL ディレクトリ）
