# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/) and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

## [1.4.0] - 2019-06-28
### Changed
- Upgrade Waggle Dance version to `3.3.2`, was `3.3.1`. See [#24](https://github.com/ExpediaGroup/apiary-waggledance-docker/issues/24).

## [1.3.0] - 2019-05-29
### Changed
- Upgrade Waggle Dance version to `3.3.1`, was `3.2.0`. See [#22](https://github.com/ExpediaGroup/apiary-waggledance-docker/issues/22).

## [1.2.0] - 2019-04-23
### Added
- Install `wget` package. See [#18](https://github.com/ExpediaGroup/apiary-waggledance-docker/issues/18).

### Changed
- Upgrade Waggle Dance version to `3.2.0`, was `3.1.2`. See [#17](https://github.com/ExpediaGroup/apiary-waggledance-docker/issues/17).

## [1.1.1] - 2019-02-15
### Added
- Auto configure Waggle Dance heapsize when running on ECS.

## [1.1.0] - 2019-01-30
### Changed
- Upgrade WaggleDance version to `3.1.2`, was `3.0.0`.

### Removed
- `VERSION` file as we are using `tags` now.

## [1.0.0] - 2018-10-31
### Added
- Support connection to cross-region federated metastore. See [#12](https://github.com/ExpediaGroup/apiary-waggledance-docker/issues/12).
- Install `awscli` package.
- Add support to fetch private key from AWS Secrets Manager.

## [0.2.1] - 2018-09-21
### Changed
- Changed waggledance version to 3.0.0.
- Reduce docker layer and size. See [#9](https://github.com/ExpediaGroup/apiary-waggledance-docker/issues/9).

## [0.2.0] - 2018-08-28
### Changed
- Changed waggledance version from 2.3.1 to 2.4.2. See [#7](https://github.com/ExpediaGroup/apiary-waggledance-docker/issues/7).
