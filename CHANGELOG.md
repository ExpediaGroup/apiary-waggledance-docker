# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/) and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

## [1.8.5] - 2021-12-20
### Changed
- Upgrade Waggle Dance version to `3.9.8` (was `3.9.4`) fix log4j-shell vulnerabilities. https://logging.apache.org/log4j/2.x/security.html

## [1.8.4] - 2021-05-27
### Changed
- Upgrade APIARY_EXTENSIONS_VERSION to `7.2.2` was `7.2.1`

## [1.8.3] - 2021-05-25
### Changed
- Upgrade APIARY_EXTENSIONS_VERSION to `7.2.1` was `7.2.0`

## [1.8.2] - 2021-05-21
### Changed
- Upgrade Waggle Dance version to `3.9.4` (was `3.9.3`) to fix WaggleDance issue [#216](https://github.com/HotelsDotCom/waggle-dance/issues/216).

## [1.8.1] - 2021-03-30
### Added
- Environment variable to configure waggle-dance log level.

## [1.8.0] - 2021-03-18
### Added
- Add apiary extensions hive-hook jar to replace s3 paths as alluxio paths.

## [1.7.1] - 2021-03-15
### Changed
- Upgrade Waggle Dance version to `3.9.3` (was `3.9.1`) to fix NullPointerException in `get_privilege_set` call.

## [1.7.0] - 2021-03-04
### Changed
- Upgrade Waggle Dance version to `3.9.1` (was `3.8.0`) to fix Presto view issues and support metastore filters.

## [1.6.0] - 2021-01-14
### Changed
- Upgrade Waggle Dance version to `3.8.0`, was `3.6.0`.

## [1.5.0] - 2020-03-05
### Changed
- Upgrade Waggle Dance version to `3.6.0`, was `3.3.2`.

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
