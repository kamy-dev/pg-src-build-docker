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

### 接続方法

コンテナ起動後、以下の方法で PostgreSQL に接続できます：

```bash
# コンテナ内でpsqlを使用
docker exec -it postgres-container bash
su - postgres
psql

# または外部から接続
psql -h localhost -p 5432 -U postgres
```

### PL/Python 拡張の有効化

```sql
CREATE EXTENSION plpython3u;
```

## OSS 貢献における Docker コンテナの制約

Docker コンテナ環境では以下の領域での OSS 貢献に制約があります：

1. **カーネルレベルの機能開発**: Docker コンテナはホストのカーネルを共有するため、カーネルモジュールやシステムコールに関わる機能の開発・テストができません。

2. **ハードウェア依存の最適化**: 実機の特定の CPU 機能（AVX、NUMA 等）やストレージデバイス固有の最適化に関する貢献は、仮想化環境では正確な検証が困難です。

3. **システム管理・運用ツール**: systemd サービス、init 管理、システム全体のリソース管理など、OS レベルの統合に関する機能は制約があります。

## 開発環境の詳細

-   **ベースイメージ**: Ubuntu 22.04 LTS
-   **PostgreSQL ソース**: 公式 Git リポジトリから Clone
-   **ビルド設定**: OpenSSL、libxml、libxslt、Python 拡張を有効化
-   **データ永続化**: `/pgsql`（データディレクトリ）、`/wal`（WAL ディレクトリ）
