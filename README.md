# dcape-app-redmine

[![GitHub Release][1]][2] [![GitHub code size in bytes][3]]() [![GitHub license][4]][5]

[1]: https://img.shields.io/github/release/dopos/dcape-app-redmine.svg
[2]: https://github.com/dopos/dcape-app-redmine/releases
[3]: https://img.shields.io/github/languages/code-size/dopos/dcape-app-redmine.svg
[4]: https://img.shields.io/github/license/dopos/dcape-app-redmine.svg
[5]: LICENSE

[Redmine](https://en.wikipedia.org/wiki/Redmine) application configuration for set: plugins, passenger, configured postgresql backend for automated deploy of [dcape](https://github.com/dopos/dcape).

## Docker image used

* [redmine](https://hub.docker.com/r/abhinand12/redmine3.4-plugins-passenger/) special builded image

## Requirements

* linux 64bit (git, make, wget, gawk, openssl)
* [docker](http://docker.io)
* [dcape](https://github.com/dopos/dcape)
* Git service ([github](https://github.com), [gitea](https://gitea.io) or [gogs](https://gogs.io))

## Usage

For deploy this project need direct root access to the server

* Fork this repo in your Git service
* Setup deploy hook 
* Run "Test delivery" (config sample will be created in dcape)
* Put data to the config (keep _CI_HOOK_ENABLED=no)
* Run `make build` in deploy catalog on the server (build image, create persist subdirs and copy data)
* Run `make start` in deploy catalog for migrate plugins data
* Run in container: `bundle exec rake redmine:plugins:migrate RAILS_ENV=production` for user redmine
* Run in container: `bundle exec rake redmine:plugins:assets RAILS_ENV=production` for user redmine
* Run `make stop` and `make start` again for restart redmine and load plugins
* Set REDMINE_NO_DB_MIGRATE=yes and REDMINE_PLUGINS_MIGRATE set to empty

TODO
Add manual for use database backup (create with -t option and restore, set variables and other)

See also: [Deploy setup](https://github.com/dopos/dcape/blob/master/DEPLOY.md) (in Russian)

## License

The MIT License (MIT), see [LICENSE](LICENSE).

2018 Maxim Danilin <zan@whiteants.net>
