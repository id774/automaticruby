# Releasing Automatic Ruby

This is the maintainer runbook for building and publishing the `automatic` gem.
It describes a manual release. Building and inspecting a gem does not publish
it; `gem push` does, and must be run only for an explicitly approved release.

The governing principles are:

- Build locally.
- Verify before publishing.
- Keep credentials out of the repository.
- Publish only an explicitly approved release.

Do not restore the historical Jeweler tasks. `automatic.gemspec` is maintained
by hand, `Rakefile` contains test tasks only, and RubyGems builds the package
directly from the gemspec.

## 1. Prerequisites

The releaser needs:

- a supported Ruby, currently Ruby 3.3 through 4.0;
- current Bundler and RubyGems versions compatible with that Ruby;
- write access to the source repository and permission to create and push tags;
- ownership of `automatic` on RubyGems.org, or an API key with push permission;
- access to the RubyGems.org account and its required MFA method.

Check the local tools before changing release metadata:

```sh
ruby -v
gem --version
bundle --version
```

The release Ruby need not reproduce the complete CI matrix locally. Required
GitHub Actions checks must be green on Ruby 3.3, 3.4 and 4.0 before publication.

## 2. Authentication and credentials

RubyGems authenticates publishing operations with an API key. Confirm the
account is an owner of the package before release; gem ownership grants the
ability to push versions and yank releases. Use the least privilege needed for
the release and follow the current RubyGems.org account and API-key guidance.

The standard RubyGems sign-in command stores a key in the RubyGems credentials
file:

```sh
gem signin
```

RubyGems commonly uses `~/.gem/credentials`; with the XDG directory layout it
may report another user-specific path. Use the path reported by the installed
RubyGems. The file contains secrets and must be readable and writable only by
its owner:

```sh
chmod 0600 ~/.gem/credentials
```

Never put an API key, password, OTP or credentials file in this repository, the
Gemfile, the gemspec, a shell script, README, a commit or a GitHub artifact. Do
not show a real key in an example. Do not pass a key as a literal command-line
argument, because process listings and shell history may retain it.

The gemspec sets `rubygems_mfa_required` to `true`. If RubyGems.org requires
MFA, complete the interactive prompt from `gem signin` or `gem push`. RubyGems
also supports `--otp CODE` and the short-lived `GEM_HOST_OTP_CODE` environment
variable. Do not store an OTP in the repository or a persistent script.

Before the release window, verify access through the RubyGems.org web account.
Do not change owners or create, rotate or revoke production keys as an
incidental part of this runbook.

## 3. Prepare the source version

Start from a clean checkout of the release branch and fetch the authoritative
remote. Review the complete release diff and the top entry in `doc/VERSIONS`.

Automatic Ruby uses a calendar version taken from the release date:

```text
X.YY        release in year X, month YY
X.YY.PATCH  correction to an earlier release in the same month
```

Section 10 of `POLICY.md` is authoritative. A release updates these three
places together in one release-metadata commit:

- `VERSION` contains the package version;
- `lib/automatic/version.rb` defines `Automatic::VERSION` for the CLI;
- the current heading in `doc/VERSIONS` contains the same version.

`automatic.gemspec` does not contain another version literal. It reads and
strips the repository-root `VERSION` file. Confirm all three values agree:

```sh
version=$(cat VERSION)
ruby -Ilib -e "require 'automatic/version'; abort unless Automatic::VERSION == '$version'"
ruby -e 'spec = Gem::Specification.load("automatic.gemspec")
  abort unless spec.version.to_s == File.read("VERSION").strip'
```

Finalize the current unreleased `doc/VERSIONS` entry as a release summary, not
a development diary. Change `(Release Date: TBD)` to the actual release date.
Do not add a bullet merely for finalizing the date. Remove or consolidate an
unreleased bullet only when it does not describe the source being published.

## 4. Run release checks

Install the default development bundle and run the same default suite used by
the repository:

```sh
bundle install
bundle exec rake
bundle exec ruby -Ilib -e "require 'automatic'"
bundle exec bin/automatic --version
bundle exec bin/automatic --help
```

Also confirm that all required GitHub Actions checks are green for the release
commit. Do not publish from an uncommitted or dirty tree:

```sh
git status --short
```

## 5. Build the gem

Build from the hand-maintained gemspec at the repository root:

```sh
gem build automatic.gemspec
```

This creates `automatic-X.Y.Z.gem` in the current directory. Here and below,
`X.Y.Z` means the exact value in `VERSION`; the project version may have two or
three components. The generated archive is ignored by Git and is not source.
Never commit it.

For copy-and-paste-safe inspection commands, capture its exact name:

```sh
version=$(cat VERSION)
package="automatic-${version}.gem"
test -f "$package"
```

## 6. Inspect package contents

First inspect the archive's recorded file list without installing it:

```sh
gem specification "$package" files
```

For a filesystem view, unpack it into a fresh temporary directory:

```sh
inspect_dir=$(mktemp -d)
gem unpack "$package" --target "$inspect_dir"
find "$inspect_dir/automatic-$version" -type f | sort
```

Confirm that the package contains, at minimum:

- `lib/` and `lib/automatic/version.rb`;
- `bin/automatic`, recorded as the `automatic` executable;
- the maintained files under `plugins/`;
- the shipped configuration and assets;
- maintained documentation, including `README.md` and `doc/RELEASING.md`;
- `doc/LICENSE.md`, `doc/COPYING` and `doc/COPYING.LESSER`;
- `VERSION` and `automatic.gemspec`.

Confirm that it does not contain:

- a generated `.gem` archive or `pkg/` output;
- `.git`, `.github`, `.bundle`, `Gemfile.lock` or local Bundler directories;
- `Gemfile`, `Rakefile`, `script/`, `spec/`, `test/` or `vendor/`;
- credentials, databases, editor files, temporary files or coverage output;
- documents deleted or superseded in the maintained source tree.

The gemspec deliberately derives its list from files visible to Git, then
filters development and generated paths. Inspect every release archive anyway:
the build result, rather than the intended filter, is what would be published.

## 7. Inspect package metadata

Read metadata from the built archive, not only from the source gemspec:

```sh
gem specification "$package" name
gem specification "$package" version
gem specification "$package" summary
gem specification "$package" homepage
gem specification "$package" metadata
gem specification "$package" required_ruby_version
gem specification "$package" licenses
gem specification "$package" authors
gem specification "$package" dependencies
```

Confirm that:

- the name is `automatic` and the version equals `VERSION`;
- the summary and homepage describe this project;
- `source_code_uri` is the Automatic Ruby repository;
- the required Ruby version is `>= 3.3.0`;
- licenses contain both `GPL-3.0-only` and `LGPL-3.0-only`;
- the authors are correct;
- runtime and development dependencies match `automatic.gemspec`, and the
  runtime ones are the framework's own — no gem that belongs to a plugin has
  found its way in ([`POLICY.md`](POLICY.md) section 9.1);
- `rubygems_mfa_required` is `true`.

## 8. Test an isolated local installation

Install the archive into a temporary gem home so the smoke test does not load
the checkout's `lib/` directory. Dependency downloads may require network
access if they are not already cached.

```sh
gem_home=$(mktemp -d)
env -u RUBYLIB GEM_HOME="$gem_home" GEM_PATH="$gem_home" \
  gem install "./$package" --no-document
env -u RUBYLIB GEM_HOME="$gem_home" GEM_PATH="$gem_home" \
  "$gem_home/bin/automatic" --version
env -u RUBYLIB GEM_HOME="$gem_home" GEM_PATH="$gem_home" \
  "$gem_home/bin/automatic" --help
```

Confirm the installed version equals `VERSION`. Then run the offline Quick
Start shape with a temporary home and a minimal Recipe:

```sh
smoke_home=$(mktemp -d)
mkdir -p "$smoke_home/.automatic/config"
cat >"$smoke_home/.automatic/config/smoke.yml" <<'YAML'
plugins:
  - module: SubscriptionText
    config:
      feeds:
        - title: release smoke test
          url: https://example.com/
  - module: PublishConsoleLink
YAML
env -u RUBYLIB HOME="$smoke_home" GEM_HOME="$gem_home" GEM_PATH="$gem_home" \
  "$gem_home/bin/automatic" -c smoke.yml
```

The command must print the example link without loading a file from the source
checkout. Remove the temporary directories when inspection is complete:

```sh
rm -rf "$inspect_dir" "$gem_home" "$smoke_home"
```

## 9. Prepare the release commit and tag

After tests and package checks pass, commit the finalized release metadata.
Wait for required CI on that exact commit. Create an annotated tag named with
the version prefixed by `v`, as required by the existing version policy:

```sh
version=$(cat VERSION)
git tag -a "v$version" -m "Release $version"
git push origin HEAD
git push origin "v$version"
```

The tag identifies the source used to build the gem. Do not move or force-update
a release tag after publication. If the tag is wrong before publication, stop
and correct it openly. If publication has happened, preserve the source history
and make the correction in a new commit and version.

The repository has no established requirement for a GitHub Release separate
from its Git tag. If maintainers create one, create it from the same immutable
tag and use the finalized `doc/VERSIONS` entry as its notes. The tag records the
source; the RubyGems version records the published package. Neither replaces
the other.

## 10. Publish to RubyGems.org

Reconfirm approval, the package name and the version immediately before this
step. The following command performs the real publication to RubyGems.org:

```sh
gem push "automatic-X.Y.Z.gem"
```

Replace the placeholder with the archive already inspected. **Running this
command actually publishes the gem.** Do not run it for a dry run, a test, or
merely because the build succeeded. Complete any MFA prompt using the approved
RubyGems.org account.

RubyGems.org does not provide an overwrite operation for an existing name,
version and platform. A published version is immutable: never rebuild the same
version and expect a second push to replace it.

## 11. Verify publication

Open <https://rubygems.org/gems/automatic> and confirm the new version appears.
Verify its version, both licenses, required Ruby version, dependency metadata,
homepage and source link against the archive inspected above.

Allow for normal index propagation, then install from RubyGems.org into another
fresh gem home rather than reusing the local-package test:

```sh
verify_home=$(mktemp -d)
version=X.Y.Z
GEM_HOME="$verify_home" GEM_PATH="$verify_home" \
  gem install automatic -v "$version" --no-document
GEM_HOME="$verify_home" GEM_PATH="$verify_home" \
  "$verify_home/bin/automatic" --version
GEM_HOME="$verify_home" GEM_PATH="$verify_home" \
  "$verify_home/bin/automatic" --help
rm -rf "$verify_home"
```

The installed version must equal the tag, `VERSION`, `Automatic::VERSION`, the
`doc/VERSIONS` heading and the version shown by RubyGems.org.

## 12. Publication failures and corrections

Stop on an error and diagnose it; do not bypass RubyGems security controls.

- **Authentication failure:** run `gem signin` for the correct account, check
  the credentials path and permissions, and verify that the key is active and
  has push scope. Never paste the key into source or a committed script.
- **MFA failure:** use the current OTP for the account and retry only the failed
  push. Check the account's MFA configuration rather than disabling MFA.
- **Ownership failure:** have an existing owner grant the intended account
  ownership or an appropriately scoped key. Do not publish under another name.
- **Version already exists:** do not attempt to overwrite it. Determine whether
  it was already published correctly; otherwise fix the source, increment the
  version according to `POLICY.md`, rebuild and repeat every verification step.
- **Malformed metadata or rejected gem:** fix the gemspec and release metadata,
  increment the version if that version reached RubyGems.org, then rebuild,
  inspect and test the new archive. Do not use `--force` to hide validation.

`gem yank automatic -v X.Y.Z` removes a published version from normal index use.
Yank only for an exceptional serious mispublication, such as exposed secrets or
a release that must not be installed. It is not the normal correction process,
does not make the version reusable, and does not erase every downloaded copy.
The normal response is to correct the problem, bump the version and publish a
new release. Rotate any exposed secret immediately as well as yanking.

Publication state and Git history are separate. Never rewrite a published
commit, force-push the release branch, or move a release tag to simulate a
rollback. Preserve a traceable record and publish a corrected version.

Future automation may use a publishing mechanism currently supported by
RubyGems.org, but introducing automatic publication or trusted publishing is a
separate, explicitly reviewed change.

## Official RubyGems references

Recheck these official references when preparing a release, because account and
security behavior can change independently of this repository:

- [Publishing your gem](https://guides.rubygems.org/publishing/)
- [RubyGems command reference](https://guides.rubygems.org/command-reference/)
- [API key scopes](https://guides.rubygems.org/api-key-scopes/)
- [MFA requirement opt-in](https://guides.rubygems.org/mfa-requirement-opt-in/)
- [Removing a published gem](https://guides.rubygems.org/removing-a-published-gem/)

## Quick checklist

- [ ] `VERSION`, `Automatic::VERSION` and the `doc/VERSIONS` heading agree.
- [ ] The release date and release summary are finalized.
- [ ] The working tree is clean and required CI is green.
- [ ] `bundle exec rake` passes and the gem builds.
- [ ] Package contents and metadata have been inspected.
- [ ] GPLv3/LGPLv3, Ruby version and dependencies are correct.
- [ ] The isolated local install and Quick Start smoke test pass.
- [ ] The release commit and immutable `vX.Y.Z` tag identify the built source.
- [ ] Publication has explicit approval and `gem push` succeeds.
- [ ] RubyGems.org metadata and a clean remote install are verified.
