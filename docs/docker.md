# Zetzy Web — Panduan Docker & GHCR

Repositori ini mendukung distribusi **Zetzy Web** melalui **GitHub Container Registry (GHCR)** secara otomatis setiap kali merilis tag versi (`v*`) atau menjalankan workflow secara manual lewat GitHub Actions ([build-deploy.yml](file:///Users/umardani/Documents/workspace/zetzy/.github/workflows/build-deploy.yml)).

---

## 1. Menjalankan Langsung dari GHCR (Paling Praktis)

Image multi-arsitektur (`linux/amd64` dan `linux/arm64`) berbasis `nginx:1.27-alpine` dipublikasikan ke:

```
ghcr.io/zenalghi/zetzy:latest
```

### Dengan `docker run`

```bash
docker pull ghcr.io/zenalghi/zetzy:latest
docker run -d \
  --name zetzy-web \
  --restart unless-stopped \
  -p 8080:80 \
  ghcr.io/zenalghi/zetzy:latest
```

Lalu buka `http://localhost:8080` di browser.

### Dengan `docker-compose.yml`

```yaml
services:
  zetzy:
    image: ghcr.io/zenalghi/zetzy:latest
    container_name: zetzy-web
    restart: unless-stopped
    ports:
      - "8080:80"
```

Jalankan:

```bash
docker compose up -d
```

> **Catatan Visibilitas GHCR:** Setelah workflow pertama kali mem-push image ke GHCR, pastikan package **`zetzy`** di tab **GitHub Packages** akun Anda diset ke **Public** (Settings → Package settings → Change visibility → Public) agar server/perangkat lain bisa `docker pull` tanpa login token.

---

## 2. Build Sendiri Langsung dari Source (Opsional)

Jika ingin membangun image secara lokal langsung dari repository tanpa menginstal Flutter SDK di mesin host:

```bash
# Mode offline-first saja:
docker build -t zetzy-web .

# Dengan koneksi cloud Supabase:
docker build \
  --build-arg SUPABASE_URL="https://PROJECT_REF.supabase.co" \
  --build-arg SUPABASE_ANON_KEY="YOUR_SUPABASE_ANON_KEY" \
  -t zetzy-web .

docker run -d -p 8080:80 zetzy-web
```

---

## 3. Catatan Teknis CI/CD (`--base-href`)

* **GitHub Pages** memakai `--base-href "/zetzy/"` karena di-serve di subpath `https://zenalghi.github.io/zetzy/`.
* **Container Docker (GHCR)** otomatis di-build memakai `--base-href "/"` sehingga bisa langsung berjalan di root domain atau port apa pun (`http://localhost:8080/`, `https://zetzy.domainanda.com/`).
* Image dibangun menggunakan [docker/Dockerfile.ci](file:///Users/umardani/Documents/workspace/zetzy/docker/Dockerfile.ci) + [docker/nginx.conf](file:///Users/umardani/Documents/workspace/zetzy/docker/nginx.conf) (mendukung SPA fallback, gzip, dan cache statis).
