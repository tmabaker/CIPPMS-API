# Security Policy

This repository is a private fork of [CIPP-API](https://github.com/KelvinTegelaar/CIPP-API),
operated by NO & SE IT Group (NOIT) to deploy CIPP to NOIT-managed Azure
Function Apps. It is kept in sync with upstream automatically.

## Reporting a Vulnerability

- **Vulnerabilities in this fork's owner-specific configuration** (the deploy
  workflows, `pull.yml`, container/build config, or NOIT's Azure deployments):
  report privately using this repository's **GitHub Security Advisories**
  ("Report a vulnerability" under the Security tab). Please do **not** open a
  public issue or pull request for security matters.

- **Vulnerabilities in upstream CIPP code** (anything under `Modules/`,
  `profile.ps1`, HTTP triggers, or other code inherited from upstream): report
  them to the upstream project per its policy at
  https://github.com/KelvinTegelaar/CIPP-API/security/policy so the fix reaches
  all CIPP users. See also the CIPP documentation at https://docs.cipp.app.

We aim to acknowledge reports within a few business days and will coordinate
disclosure and remediation with upstream where the issue originates there.
