# Original operator notes

This file is retained for historical context. The archived repository does not
provide a hosted bot or a supported deployment service.

The original Daki deployment flow depended on a private deployment client,
private runtime configuration, a separate Sefbot checkout, and an operator
account. Those dependencies are intentionally not included in this public
repository. `scripts/deploy-daki.sh`, `scripts/deploy.sh`, and related scripts
are not a general-purpose deployment path. Do not run them unless you are the
original operator and have independently reviewed their behavior and private
dependencies.

For a new installation, use [self-hosting](SELF_HOSTING.md) and configure an
environment you control. Never commit credentials, databases, logs, or runtime
backups.
