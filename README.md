# 📘 Overview

This repository provides a production-grade **Apache2 on Ubuntu** container for the public landing page of **Punctiq**.  
It is designed to run **behind HAProxy** on the same Docker network and includes:

- Hardened Apache setup (Ubuntu 24.04 base)
- Enabled modules: `headers`, `rewrite`, `remoteip`
- Global security headers (HSTS, XFO, XCTO, Referrer-Policy, Permissions-Policy)
- Real client IP logging via `mod_remoteip`
- `/health` endpoint for HAProxy health checks
- “Coming Soon” page with **dark+light theme (auto + toggle)**
- **Favicon** (SVG + PNG fallbacks)
- Safe default indexing (`robots.txt` blocks crawlers until go-live)

The setup is intended to be fronted by HAProxy TLS termination with a wildcard certificate and SNI routing.

---

# 📦 Project Structure

```
.
├── apache2
│   ├── remoteip.conf             # Trust proxy subnet + real client IP logs
│   └── security-headers.conf     # Global security headers + -Indexes
├── docker-compose.yml            # Apache service on external HAProxy network
├── Dockerfile                    # Ubuntu 24.04 + Apache2 + health + hardening
├── Makefile                      # Build/Run helpers (optional)
├── README.md                     # You're here
└── site
    ├── favicon-16.png            # Favicon PNG fallback (16x16)
    ├── favicon-32.png            # Fallback (32x32)
    ├── favicon.svg               # Primary vector favicon
    ├── images
    │   └── punctiq-logo.png      # Punctiq logo used in the page
    ├── index.html                # Coming Soon (dark+light + toggle)
    └── robots.txt                # Disallow all by default
```

---

# 🚀 Usage

## 🔧 Build the Docker image

```bash
make build VERSION=<version>
```

or manually:

```bash
docker build -t itcommunity/pctq-web:1.0.0 .
```

## ▶️ Run with Docker Compose

> Ensure your HAProxy container and the **external Docker network** exist (example: `pctq-edge`).

```bash
# create once if needed
docker network create pctq-edge

# start web container on the same network as HAProxy
make up
# or
docker compose up -d
```

## 🔄 Restart

```bash
make restart
```

## 🧼 Cleanup

```bash
make down
make clean
```

---

# 🛠 Configuration

| File / Path                                   | Description                                                                 |
|-----------------------------------------------|-----------------------------------------------------------------------------|
| `./Dockerfile`                                | Ubuntu 24.04 base, Apache2 install, modules on, health, hardening          |
| `apache2/security-headers.conf`               | Global security headers, `Options -Indexes`, `AllowOverride All`           |
| `apache2/remoteip.conf`                       | `RemoteIPHeader X-Forwarded-For` + **trusted proxy CIDR** + log format     |
| `site/index.html`                             | Coming Soon page (dark+light auto + manual toggle + brand logo)            |
| `site/favicon.svg` / `favicon-16.png` / `-32` | Favicon set (SVG primary + PNG fallbacks)                                  |
| `site/robots.txt`                             | Blocks indexing by default (`Disallow: /`)                                 |
| `/var/www/html/health`                        | Health endpoint returning `200 OK` (created at build time)                 |
| External Docker network (e.g. `pctq-edge`)    | Shared network with HAProxy container (SNI/TLS terminated at HAProxy)      |

### Environment Variables

No mandatory env vars for the web container.  
If you template this for multiple vhosts later, you can add `VIRTUAL_HOST`-like labels/env for your proxy.

---

# 🔖 Tagging & Versioning

We follow semantic versioning:

- `itcommunity/pctq-web:1.0.0` — stable version  
- `itcommunity/pctq-web:prod` — alias for production  
- `itcommunity/pctq-web:sha-<git-sha>` — Git-based immutable builds

Use `make tag` and `make push` if your `Makefile` includes them:

```bash
make tag
make push
```

---

# 🔌 HAProxy Backend (example)

Add a backend pointing to the Apache container (same Docker network):

```cfg
frontend fe_https
  bind *:443 ssl crt /etc/ssl/private/punctiq.pem
  acl host_punctiq  hdr(host) -i punctiq.com
  acl host_www      hdr(host) -i www.punctiq.com
  use_backend be_punctiq if host_punctiq or host_www

  http-response set-header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload"
  http-response set-header X-Content-Type-Options "nosniff"
  http-response set-header X-Frame-Options "SAMEORIGIN"
  http-response set-header Referrer-Policy "strict-origin-when-cross-origin"

backend be_punctiq
  option httpchk GET /health
  http-check expect status 200
  http-request set-header X-Forwarded-Proto https
  server pctqweb pctq-web:80 check
```

> **Note:** Update `pctq-web` to your actual container name if different.

---

# 🧩 Enabled Apache Modules & Hardening

- `headers` — sets security headers globally  
- `rewrite` — future-proofing for redirects/rules  
- `remoteip` — logs the real client IP (`X-Forwarded-For`)  
- `ServerTokens Prod` & `ServerSignature Off`  
- Directory listing disabled: `Options -Indexes`  
- HSTS is sent by HAProxy (TLS terminates at proxy). The same header is also configured at Apache level if you later terminate TLS there.

---

# 🖼 Frontend Details

- **Theme:** dark+light with `prefers-color-scheme` auto-detection and a **manual toggle** (state saved in `localStorage`).  
- **Branding:** `/site/images/punctiq-logo.png` referenced in `index.html`.  
- **Favicon:** primary `favicon.svg` + PNG fallbacks (16/32).  
- **Robots:** default **no indexing** until go-live.

---

# 👥 Contributors

**Owner:** [Punctiq Web/DevOps Team]  
**Maintainers:** [@alexandru-raul], [@devops-punctiq], [@infra-automation]

---

# 📄 License

[MIT License](https://opensource.org/licenses/MIT)