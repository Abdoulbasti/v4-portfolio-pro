import React, { useState, useEffect } from 'react';
import styled from 'styled-components';
import { Icon } from '@components/icons';
import { socialMedia } from '@config';

const GITHUB_USER = 'Abdoulbasti';
const GITHUB_API = 'https://api.github.com';
const STATS_STORAGE_KEY = 'githubStats';
const DAY_IN_MS = 24 * 60 * 60 * 1000;

const StyledFooter = styled.footer`
  ${({ theme }) => theme.mixins.flexCenter};
  flex-direction: column;
  height: auto;
  min-height: 70px;
  padding: 15px;
  text-align: center;
`;

const StyledSocialLinks = styled.div`
  display: none;

  @media (max-width: 768px) {
    display: block;
    width: 100%;
    max-width: 270px;
    margin: 0 auto 10px;
    color: var(--light-slate);
  }

  ul {
    ${({ theme }) => theme.mixins.flexBetween};
    padding: 0;
    margin: 0;
    list-style: none;

    a {
      padding: 10px;
      svg {
        width: 20px;
        height: 20px;
      }
    }
  }
`;

const StyledCredit = styled.div`
  color: var(--light-slate);
  font-family: var(--font-mono);
  font-size: var(--fz-xxs);
  line-height: 1;

  a {
    padding: 10px;
  }

  .github-stats {
    display: flex;
    flex-wrap: wrap;
    justify-content: center;
    row-gap: 5px;
    margin-top: 10px;

    & > span {
      display: inline-flex;
      align-items: center;
      margin: 0 7px;
    }
    svg {
      display: inline-block;
      margin-right: 5px;
      width: 14px;
      height: 14px;
    }
  }
`;

const fetchJson = url =>
  fetch(url).then(response => {
    if (!response.ok) {
      throw new Error(`GitHub API responded ${response.status} to ${url}`);
    }
    return response.json();
  });

// "today", "yesterday", "3 days ago", then "1 month ago", "2 months ago"
const timeAgo = date => {
  const days = Math.max(0, Math.round((Date.now() - Date.parse(date)) / DAY_IN_MS));
  return days < 30
    ? new Intl.RelativeTimeFormat('en', { numeric: 'auto' }).format(-days, 'day')
    : new Intl.RelativeTimeFormat('en').format(-Math.floor(days / 30), 'month');
};

const Footer = () => {
  const [githubStats, setGitHubStats] = useState(null);

  useEffect(() => {
    // Layout remounts the footer on every page: reuse the stats this session already fetched
    try {
      const cachedStats = sessionStorage.getItem(STATS_STORAGE_KEY);
      if (cachedStats) {
        setGitHubStats(JSON.parse(cachedStats));
        return;
      }
    } catch (e) {
      // Storage unavailable: fetch the stats below
    }

    Promise.all([
      fetchJson(`${GITHUB_API}/search/commits?q=author:${GITHUB_USER}&per_page=1`),
      fetchJson(`${GITHUB_API}/users/${GITHUB_USER}`),
      fetchJson(`${GITHUB_API}/users/${GITHUB_USER}/repos?sort=pushed&per_page=1`),
    ])
      .then(([commits, user, [lastPushedRepo]]) => {
        const stats = {
          commits: commits.total_count,
          repos: user.public_repos,
          lastPush: lastPushedRepo ? timeAgo(lastPushedRepo.pushed_at) : null,
        };
        setGitHubStats(stats);
        try {
          sessionStorage.setItem(STATS_STORAGE_KEY, JSON.stringify(stats));
        } catch (e) {
          // Not cached: the next page fetches the stats again
        }
      })
      .catch(e => console.error(e));
  }, []);

  return (
    <StyledFooter>
      <StyledSocialLinks>
        <ul>
          {socialMedia &&
            socialMedia.map(({ name, url }, i) => (
              <li key={i}>
                <a href={url} aria-label={name}>
                  <Icon name={name} />
                </a>
              </li>
            ))}
        </ul>
      </StyledSocialLinks>

      <StyledCredit>
        <a href={`https://github.com/${GITHUB_USER}`}>
          <div>Abdoulbasti MUKAILA</div>

          {githubStats && (
            <div className="github-stats">
              <span>
                <Icon name="Commit" />
                <span>{githubStats.commits.toLocaleString('en-US')} commits</span>
              </span>
              <span>
                <Icon name="Repo" />
                <span>{githubStats.repos.toLocaleString('en-US')} repos</span>
              </span>
              {githubStats.lastPush && (
                <span>
                  <Icon name="Clock" />
                  <span>last push {githubStats.lastPush}</span>
                </span>
              )}
            </div>
          )}
        </a>
      </StyledCredit>
    </StyledFooter>
  );
};

export default Footer;
