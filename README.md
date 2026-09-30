<div align="center">
  <img alt="Logo" src="https://raw.githubusercontent.com/bchiang7/v4/main/src/images/logo.png" width="100" />
</div>
<h1 align="center">
  brittanychiang.com - v4
</h1>
<p align="center">
  The fourth iteration of <a href="https://brittanychiang.com" target="_blank">brittanychiang.com</a> built with <a href="https://www.gatsbyjs.org/" target="_blank">Gatsby</a> and hosted with <a href="https://www.netlify.com/" target="_blank">Netlify</a>
</p>
<p align="center">
  Previous iterations:
  <a href="https://github.com/bchiang7/v1" target="_blank">v1</a>,
  <a href="https://github.com/bchiang7/v2" target="_blank">v2</a>,
  <a href="https://github.com/bchiang7/bchiang7.github.io" target="_blank">v3</a>
</p>
<p align="center">
  <a href="https://app.netlify.com/sites/brittanychiang/deploys" target="_blank">
    <img src="https://api.netlify.com/api/v1/badges/1963b488-7b78-48c9-9e2d-6fb5e47ab3af/deploy-status" alt="Netlify Status" />
  </a>
</p>

![demo](https://raw.githubusercontent.com/bchiang7/v4/main/src/images/demo.png)

## 🚨 Forking this repo (please read!)

Many people have contacted me asking me if they can use this code for their own website, and the answer to that question is usually **yes, with attribution**.

I value keeping my site open source, but as you all know, _**plagiarism is bad**_. It's always disheartening whenever I find that someone has copied my site without giving me credit. I spent a non-trivial amount of effort building and designing this iteration of my website, and I am proud of it! All I ask of you all is to not claim this effort as your own.

Please also note that I did not build this site with the intention of it being a starter theme, so if you have questions about implementation, please refer to the [Gatsby docs](https://www.gatsbyjs.org/docs/).

### TL;DR

Yes, you can fork this repo. Please give me proper credit by linking back to [brittanychiang.com](https://brittanychiang.com). Thanks!

## 🛠 Installation & Set Up

1. Install the Gatsby CLI

   ```sh
   npm install -g gatsby-cli
   ```

2. Install and use the correct version of Node using [NVM](https://github.com/nvm-sh/nvm)

   ```sh
   nvm install
   ```

3. Install dependencies

   ```sh
   npm ci
   ```

4. Start the development server

   ```sh
   npm start
   ```

## 🚀 Building and Running for Production

1. Generate a full static production build

   ```sh
   npm run build
   ```

1. Preview the site as it will appear once deployed

   ```sh
   npm run serve
   ```

## 🐳 Docker

The site is deployed as a Docker image on a VPS, behind the Caddy reverse proxy of the [vps-infrastructure](https://github.com/Abdoulbasti/vps-infrastructure) platform. Caddy handles TLS and domains. Inside the image, a non-root nginx serves the static build (`public/`) on port 8080 and applies the site's own rules: Gatsby caching headers, `/page` → `/page/` redirects, the 404 page and a `/healthz` endpoint.

| File                                   | Purpose                                                                              |
| -------------------------------------- | ------------------------------------------------------------------------------------ |
| `Dockerfile`                           | `development` target (gatsby develop), `production` target (nginx serving `public/`) |
| `docker/nginx/default.conf`            | nginx rules for the static site                                                      |
| `docker-compose.base.yml`              | Hardening shared by test, prod and the local preview (read-only, no capabilities)    |
| `docker-compose.dev.yml`               | Local development and local preview of the production image                          |
| `docker-compose.test.yml`, `.prod.yml` | Test and production, attached to the platform's `test_net` / `prod_net` networks     |
| `.github/workflows/docker.yml`         | Builds the image and publishes it to GHCR                                            |

Run `make help` to list every command. Local development needs Docker Compose 2.22 or later.

### Local development

```sh
make dev       # gatsby develop with hot reload: http://localhost:8000
make preview   # the production image, as it runs in test and prod: http://localhost:9000
make clean     # delete the dev containers and Gatsby cache volumes
```

`make dev` uses Compose Watch: edits in `src/`, `content/`, `static/` and `gatsby-browser.js` are synced into the container and hot-reloaded, changes to `gatsby-config.js`, `gatsby-node.js`, `gatsby-ssr.js` and `.babelrc` restart it, and changes to `package*.json` rebuild the image.

### Publishing images

The GitHub Actions workflow publishes `ghcr.io/abdoulbasti/v4-portfolio-pro`:

| Event          | Tags                                     | Deployed to |
| -------------- | ---------------------------------------- | ----------- |
| Push to `main` | `main`, `sha-<commit>`                   | test        |
| Tag `vX.Y.Z`   | `X.Y.Z`, `X.Y`, `latest`, `sha-<commit>` | production  |
| Pull request   | none (build only)                        | —           |

The package must be public so the VPS can pull it without logging in (GitHub → Packages → v4-portfolio-pro → Package settings → Change visibility).

### Deploying on the VPS

The platform must be running (`make start` in vps-infrastructure). From a clone of this repository on the VPS:

```sh
make deploy ENV=test                      # pulls :main
make deploy ENV=prod                      # pulls :latest, asks for confirmation
make deploy ENV=prod IMAGE_TAG=1.0.0      # roll back, or promote an exact image (sha-<commit>)
make logs ENV=prod
```

Caddy reaches the containers by name, on the platform networks: `abdoulbasti-mukaila.com` → `portfolio_prod_web:8080`, and `portfolio-test.abdoulbasti-mukaila.com` → `portfolio_test_web:8080`. The test site also sends `X-Robots-Tag: noindex`. The containers publish no ports.

## 📈 Analytics (to do)

The site has no analytics for now. The Gatsby 5 migration removed `gatsby-plugin-google-analytics`, because it used Brittany Chiang's Universal Analytics ID and Google shut down Universal Analytics in July 2023.

To add Google Analytics 4 once you have a measurement ID (`G-XXXXXXXXXX`):

1. Install the plugin

   ```sh
   npm install gatsby-plugin-google-gtag
   ```

1. Add it to `plugins` in `gatsby-config.js`

   ```js
   {
     resolve: `gatsby-plugin-google-gtag`,
     options: {
       trackingIds: ['G-XXXXXXXXXX'],
     },
   },
   ```

1. Check it in a production build (`npm run build && npm run serve`). The plugin does nothing in `npm start`.

Analytics cookies need visitor consent in the EU, so plan for a consent banner too.

## 🎨 Color Reference

| Color          | Hex                                                                |
| -------------- | ------------------------------------------------------------------ |
| Navy           | ![#0a192f](https://via.placeholder.com/10/0a192f?text=+) `#0a192f` |
| Light Navy     | ![#112240](https://via.placeholder.com/10/0a192f?text=+) `#112240` |
| Lightest Navy  | ![#233554](https://via.placeholder.com/10/303C55?text=+) `#233554` |
| Slate          | ![#8892b0](https://via.placeholder.com/10/8892b0?text=+) `#8892b0` |
| Light Slate    | ![#a8b2d1](https://via.placeholder.com/10/a8b2d1?text=+) `#a8b2d1` |
| Lightest Slate | ![#ccd6f6](https://via.placeholder.com/10/ccd6f6?text=+) `#ccd6f6` |
| White          | ![#e6f1ff](https://via.placeholder.com/10/e6f1ff?text=+) `#e6f1ff` |
| Green          | ![#64ffda](https://via.placeholder.com/10/64ffda?text=+) `#64ffda` |
