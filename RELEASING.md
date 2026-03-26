# Releasing

This repo contains two gems that are released independently:

| Gem | Version file | Gemspec |
|-----|-------------|---------|
| manticore-client | `lib/manticore/client/version.rb` | `manticore-client.gemspec` |
| manticore-rails | `lib/manticore-rails/version.rb` | `manticore-rails.gemspec` |

## Prerequisites

- Push access to RubyGems for both gems
- All specs passing: `bundle exec rspec`

## Versioning

The gems are versioned independently. `manticore-rails` depends on `manticore-client ~> 1.0`, so a major version bump in `manticore-client` requires a corresponding update in `manticore-rails.gemspec`.

Follow [Semantic Versioning](https://semver.org/):

- **patch** (1.0.x) — bug fixes, no API changes
- **minor** (1.x.0) — new features, backward compatible
- **major** (x.0.0) — breaking changes

## Release process

### 1. Update version

Edit the version file for the gem you're releasing:

```ruby
# manticore-client
# lib/manticore/client/version.rb
VERSION = "1.1.0"

# manticore-rails
# lib/manticore-rails/version.rb
VERSION = "0.2.0"
```

### 2. Update lockfile

```bash
bundle install
```

### 3. Commit and tag

```bash
git add -A
git commit -m "Release manticore-client v1.1.0"
git tag manticore-client-v1.1.0

# or for manticore-rails:
git commit -m "Release manticore-rails v0.2.0"
git tag manticore-rails-v0.2.0
```

### 4. Build and push

```bash
gem build manticore-client.gemspec
gem push manticore-client-1.1.0.gem

# or for manticore-rails:
gem build manticore-rails.gemspec
gem push manticore-rails-0.2.0.gem
```

### 5. Push tags

```bash
git push origin main --tags
```

## Releasing both gems at once

When a change affects both gems (e.g., a shared namespace rename), release `manticore-client` first since `manticore-rails` depends on it:

```bash
# 1. Bump both versions
# 2. Commit
git commit -m "Release manticore-client v1.1.0 and manticore-rails v0.2.0"
git tag manticore-client-v1.1.0
git tag manticore-rails-v0.2.0

# 3. Build and push client first
gem build manticore-client.gemspec
gem push manticore-client-1.1.0.gem

# 4. Then push rails
gem build manticore-rails.gemspec
gem push manticore-rails-0.2.0.gem

# 5. Push tags
git push origin main --tags
```

## Verify

```bash
gem info manticore-client --remote
gem info manticore-rails --remote
```
