# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/) and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

## [1.13.0] - 2025-07-22
### Changed
- Upgrade `WAGGLE_DANCE_VERSION` to `4.0.2` (was `3.13.8`). See [Changelog](https://github.com/ExpediaGroup/waggle-dance/blob/main/CHANGELOG.md)
- Switches to new WD using Hive3 libraries (Hive2 compatible).
- Switches to new WD groupId `com.expediagroup` (was `com.hotels`).
- Added support for `WDLOGLEVEL` environment variable to set the log level of Waggle Dance package.

## [1.12.5] - 2025-06-03
### Changed
- Upgrade `WAGGLE_DANCE_VERSION` to `3.13.8` (was `3.13.7`). See [Changelog](https://github.com/ExpediaGroup/waggle-dance/blob/main/CHANGELOG.md)

## [1.12.4] - 2025-05-28
### Changed
- Upgrade `WAGGLE_DANCE_VERSION` to `3.13.7` (was `3.13.4`). See [Changelog](https://github.com/ExpediaGroup/waggle-dance/blob/main/CHANGELOG.md)

## [1.12.3] - 2024-10-04
### Changed
- Upgrade `WAGGLE_DANCE_VERSION` to `3.13.4` (was `3.13.3`). See [Changelog](https://github.com/ExpediaGroup/waggle-dance/blob/main/CHANGELOG.md)

## [1.12.2] - 2024-10-02
### Changed
- Upgrade `WAGGLE_DANCE_VERSION` to `3.13.3` (was `3.13.1`). See [Changelog](https://github.com/ExpediaGroup/waggle-dance/blob/main/CHANGELOG.md)

## [1.12.1] - 2024-05-06
### Changed
- Upgrade `WAGGLE_DANCE_VERSION` to `3.13.1` (was `3.13.0`). See [Changelog](https://github.com/ExpediaGroup/waggle-dance/blob/main/CHANGELOG.md)

## [1.12.0] - 2024-04-22
### Changed
- Upgrade `WAGGLE_DANCE_VERSION` to `3.13.0` (was `3.12.0`). See [Changelog](https://github.com/ExpediaGroup/waggle-dance/blob/main/CHANGELOG.md)

## [1.11.0] - 2024-02-08
### Changed
- Upgrade `WAGGLE_DANCE_VERSION` to `3.12.0` (was `3.11.7`). See [Changelog](https://github.com/ExpediaGroup/waggle-dance/blob/main/CHANGELOG.md)

## [1.10.6] - 2023-11-30
### Changed
- Upgrade `WAGGLE_DANCE_VERSION` to `3.11.7` (was `3.11.6`). See [Changelog](https://github.com/ExpediaGroup/waggle-dance/blob/main/CHANGELOG.md)
- Added Github Actions workflow for deploying "snapshot" versions of the docker image.

## [1.10.5] - 2023-10-25
### Changed
- Upgrade `WAGGLE_DANCE_VERSION` to `3.11.6` (was `3.11.5`). See [Changelog](https://github.com/ExpediaGroup/waggle-dance/blob/main/CHANGELOG.md)

## [YANKED - release failed] [1.10.4] - 2023-10-24
### Changed
- Upgrade `WAGGLE_DANCE_VERSION` to `3.11.6` (was `3.11.5`). See [Changelog](https://github.com/ExpediaGroup/waggle-dance/blob/main/CHANGELOG.md)

## [1.10.3] - 2023-10-23
### Changed
- Upgrade `WAGGLE_DANCE_VERSION` to `3.11.5` (was `3.11.4`). See [Changelog](https://github.com/ExpediaGroup/waggle-dance/blob/main/CHANGELOG.md)

## [1.10.2] - 2023-09-05
### Changed
- Upgrade `WAGGLE_DANCE_VERSION` to `3.11.4` (was `3.11.2`).
- sends metrics with tags.

## [1.10.1] - 2023-07-04
### Changed
- Waggledance jar was not available from Sonatype.

## [1.10.0] - 2023-07-04 - [YANKED]
### Changed
- Upgrade `WAGGLE_DANCE_VERSION` to `3.11.2` (was `3.10.14`).
  - Support kerberos and delegation-token See [#264](https://github.com/ExpediaGroup/waggle-dance/issues/264).
  - Upgrade version of snakeyaml to 1.32 (was 1.26).
  - Clean up delegation-token set for Kerberos in thread-local.
  - Setting AWSGlueClientFactory log level to `WARN` because it spams this [log](https://github.com/awslabs/aws-glue-data-catalog-client-for-apache-hive-metastore/blob/branch-3.4.0/aws-glue-datacatalog-client-common/src/main/java/com/amazonaws/glue/catalog/metastore/AWSGlueClientFactory.java#L57) every ~200ms. It could be creating unnecessary Glue clients.

## [1.9.5] - 2023-05-11
### Changed
- Upgrade `WAGGLE_DANCE_VERSION` to `3.10.14` (was `3.10.12`).

## [1.9.4] - 2023-05-08 - [YANKED]
### Changed
- Upgrade Waggle Dance version to `3.10.12` (was `3.10.11`) to upgrade `springboot` version.
- Change `amazonlinux` tag to `2` (was `latest`) to keep the build consistent.
- Upgrade github action runner from `ubuntu-18.04` to `ubuntu-22.04`.

## [1.9.3] - 2023-02-07
### Changed
- Upgrade Waggle Dance version to `3.10.11` (was `3.10.10`) to fix `show tables from <db>` when using Glue federations.

## [1.9.2] - 2022-12-01
### Changed
- Upgrade Waggle Dance version to `3.10.10` (was `3.10.9`) to add AWS STS support.

## [1.9.1] - 2022-12-01
### Changed
- Upgrade Waggle Dance version to `3.10.9` (was `3.10.8`) to add AWS STS support.

## [1.9.0] - 2022-11-25
### Changed
- Added Github Actions to build and release. From now on Docker tag images will be `v1.0.0` instead of `1.0.0`.
- Upgrade Waggle Dance version to `3.10.8` (was `3.10.6`) to add AWS STS support.

## [1.8.17] - 2022-06-07
### Changed
- Upgrade Waggle Dance version to `3.10.6` (was `3.10.5`) to fix db name translation in:
  - `alter_partitions_with_environment_context`
  - `alter_table_with_cascade`
  
## [1.8.16] - 2022-05-31
### Changed
- Upgrade APIARY_EXTENSIONS_VERSION to `7.3.2` was `7.3.1`

## [1.8.15] - 2022-05-27
### Changed
- Upgrade APIARY_EXTENSIONS_VERSION to `7.3.1` was `7.2.5`

## [1.8.14] - 2022-05-23
### Changed
- Upgrade Waggle Dance version to `3.10.5` (was `3.10.4`) another performance fix for slow responding metastores.

## [1.8.13] - 2022-05-18
### Changed
- Upgrade Waggle Dance version to `3.10.4` (was `3.10.3`) to addressing set_ugi calls issues in Looker.

## [1.8.12] - 2022-05-16
### Changed
- Upgrade Waggle Dance version to `3.10.3` (was `3.10.2`) to addressing nullpointer in set_ugi calls.

## [1.8.11] - 2022-04-19
### Changed
- Upgrade Waggle Dance version to `3.10.2` (was `3.10.1`) to addressing performance issues related to set_ugi calls.

## [1.8.10] - 2022-04-06
### Changed
- Upgrade Waggle Dance version to `3.10.1` (was `3.10.0`) to addressing performance issues when running with a high number (> 10) of metastores.

## [1.8.9] - 2022-04-06
### Changed
- Add ability to configure invocation logs separately from other `log4j` loggers using `INVOCATIONLOGLEVEL`.

## [1.8.8] - 2022-03-02
### Changed
- Fixes 1.8.7 release build

## [1.8.7] - 2022-03-01 [YANKED]
- Yanked reason: an undetected build failure during release so docker image doesn't work.
### Changed
- Upgrade Waggle Dance version to `3.10.0` (was `3.9.9`).
- Upgrade APIARY_EXTENSIONS_VERSION to `7.2.5` was `7.2.2`

## [1.8.6] - 2022-01-20
### Changed
- Upgrade Waggle Dance version to `3.9.9` (was `3.9.8`) to fix log4j-shell vulnerabilities (upgrade `log4j` to `2.17.1`). https://logging.apache.org/log4j/2.x/security.html

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
