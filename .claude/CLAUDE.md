# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Personal portfolio of Abdoulbasti MUKAILA, forked from Brittany Chiang's v4 site (Gatsby 3, React 17, styled-components 5). Much of the copy, Markdown content and some assets (logo, `static/og.png`) still belong to the original author and are being replaced. The upstream README allows forking only with attribution, so keep a visible credit linking to https://brittanychiang.com. It currently lives in `src/components/footer.js`.

## Commands

Use the Node version in `.nvmrc` (14.16.0) and yarn. `yarn.lock` is committed and `package-lock.json` is gitignored.

```sh
nvm use                      # `nvm install` the first time
yarn                         # install deps (also installs the husky hook)
npm start                    # gatsby develop: http://localhost:8000, GraphiQL at /___graphql
npm run build                # production build into public/
npm run serve                # serve the production build: http://localhost:9000
npm run clean                # delete .cache/ and public/ (do this after content-type or schema changes)
npm run format               # prettier over all js/jsx/json/md
npx eslint src gatsby-*.js   # lint (there is no lint script)
```

There is no test suite. `npm run build` is the real check, because it runs every GraphQL query and server-renders every page.

- On `/`, the server render outputs only the loader. Runtime errors in the home-page sections therefore show only in the browser, while GraphQL errors in them still fail the build.
- After a build, page-query results are in `public/page-data/**/page-data.json`. Static-query results are in `public/page-data/sq/d/*.json`.

The husky pre-commit hook runs lint-staged. It applies Prettier to staged js, css, json and md files, and `eslint --fix` to staged js. The configs come from `@upstatement/prettier-config` (see `prettier.config.js`) and `@upstatement/eslint-config/react` (see `.eslintrc`).

## Architecture

### Content flow

`gatsby-source-filesystem` loads `content/` and `src/images/`. `gatsby-transformer-remark` converts Markdown with plugins for external links, responsive images, code titles and Prism. A code block titled like `js:title=app.js` shows a filename. Queries pick a content type by path, for example `filter: { fileAbsolutePath: { regex: "/content/jobs/" } }`, so a content type is defined by its directory.

| Files                                                     | Used by                                                                                        | Frontmatter                                                                  |
| --------------------------------------------------------- | ---------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------- |
| `content/jobs/<Company>/index.md` (body is a bullet list) | `sections/jobs.js`, sorted by `date` DESC                                                      | `date, title, company, location, range, url`                                 |
| `content/featured/<Name>/index.md` plus its cover image   | `sections/featured.js`, sorted by `date` ASC                                                   | `date, title, cover, tech, github, external, cta`                            |
| `content/projects/<Name>.md`                              | `sections/projects.js` (home grid, hides `showInProjects: false`) and `pages/archive.js` (all) | `date, title, tech, github, external, ios, android, company, showInProjects` |
| `content/posts/<slug>/index.md`                           | `pages/pensieve/*`, `templates/post.js`, `templates/tag.js`                                    | `title, description, date, draft, slug, tags`                                |

- Featured `date` is only a sort key, and some entries use values like `'2'`. `cover` is a path relative to the Markdown file. `cta` renders a "Learn More" button and hides the external-link icon.
- A post's `slug` is its full URL path, such as `/pensieve/clickable-cards`. `gatsby-node.js` creates the page at that path, and `templates/post.js` finds the post by `$path`. `gatsby-node.js` also creates `/pensieve/tags/<kebab-case-tag>/` pages.
- The blog lives at `/pensieve` and is not linked from the nav.

### GraphQL schema is inferred

There is no `createSchemaCustomization`, so frontmatter types come from whatever files exist. If you delete the last file that uses a queried field, the build fails with `Cannot query field "…" on type "MarkdownRemarkFrontmatter"`. Fields at risk include `cta`, `ios`, `android`, `company`, `showInProjects` and `draft`. Declare the types in `gatsby-node.js` rather than keeping placeholder content.

### Drafts are not private

`draft: true` only hides a post from `/pensieve` and from tag counts. `gatsby-node.js` still generates the post page, its tag pages and its sitemap entries.

### Where the site's content is defined

- The copy for Hero, About and Contact is hard-coded JSX in `src/components/sections/`.
- `src/config.js` holds the email, social links, nav links and ScrollReveal preset.
- SEO metadata lives in `siteMetadata` in `gatsby-config.js`, which `src/components/head.js` reads.
- Each social link's `name` must match a case in `src/components/icons/icon.js`. Otherwise the generic external-link icon renders.

### Page shell

Every page renders `<Layout location={location}>` itself, without `wrapPageElement`, so Layout remounts on each navigation.

- On `/`, Layout shows the full-screen anime.js loader first, including during SSR, and passes `isHome` to the nav and the side rails to stagger their entrance.
- Layout also scrolls to `location.hash`, and it sets `target="_blank"` on every link whose host differs from the page's.

### Motion and SSR

Animated components follow one pattern:

1. They call `usePrefersReducedMotion()` and render static markup when reduced motion is preferred.
2. Otherwise they use `TransitionGroup`/`CSSTransition` with the class names in `src/styles/TransitionStyles.js` (`fadeup`, `fadedown`, `fade`).
3. Scroll-in effects use `sr.reveal(ref, srConfig())` inside an effect.

Server-side rendering has two constraints:

- `src/utils/sr.js` exports `null` on the server.
- `gatsby-node.js` replaces `scrollreveal`, `animejs` and `miniraf` with a null loader in HTML builds. A new browser-only library needs the same treatment, or it must only be used inside effects.

The timing constants `navDelay` and `loaderDelay` live in `src/utils/index.js`.

### Styling

The site uses styled-components only.

- **Design tokens** are CSS custom properties in `src/styles/variables.js`, such as `--green`, `--navy`, `--fz-*` and `--nav-height`.
- **Duplicated colors.** `config.colors` repeats three palette values for the web manifest and image placeholders, so change colors in both places.
- **Theme object.** `ThemeProvider` receives `{ bp, mixins }`. Styled components use it like `${({ theme }) => theme.mixins.bigButton}`.
- **Shared classes** are defined in `GlobalStyle.js`, including `numbered-heading`, `big-heading`, `inline-link`, `fancy-list` and `breadcrumb`.
- **Blurred images.** `GlobalStyle.js` blurs any `img` with `alt=""` or no `alt`.
- **Section numbers** ("01.", "02.") come from a CSS counter that `src/pages/index.js` resets, so the section order sets the numbering.
- **Fonts** (Calibre, SF Mono) are self-hosted from `src/fonts` through `src/styles/fonts.js`.

### Imports

`gatsby-node.js` defines these webpack aliases: `@components`, `@config`, `@fonts`, `@hooks`, `@images`, `@pages`, `@styles` and `@utils`.

- Components usually come from the barrel file `src/components/index.js`, as in `import { Layout } from '@components'`. Icons come from `@components/icons`.
- The barrel re-exports the home sections, so any page that imports from it also loads their static-query data.
