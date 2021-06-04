# dcape-app-redmine

[![GitHub Release][1]][2] [![GitHub code size in bytes][3]]() [![GitHub license][4]][5]

[1]: https://img.shields.io/github/release/dopos/dcape-app-redmine.svg
[2]: https://github.com/dopos/dcape-app-redmine/releases
[3]: https://img.shields.io/github/languages/code-size/dopos/dcape-app-redmine.svg
[4]: https://img.shields.io/github/license/dopos/dcape-app-redmine.svg
[5]: LICENSE

[Redmine](https://en.wikipedia.org/wiki/Redmine) application configuration for automatic build custom docker image, deploy and use with [dcape](https://github.com/dopos/dcape). Image building with public plugins and theme.

### Building docker image content

#### Plugins
* [sidebar_hide](https://github.com/jouve/sidebar_hide)
* [redmine-fixed-header](https://github.com/YujiSoftware/redmine-fixed-header.git)
* [redmine_drawio](https://github.com/mikitex70/redmine_drawio.git)
* [redmine_wiki_lists](https://github.com/tkusukawa/redmine_wiki_lists.git)
* [redmine_theme_changer](https://github.com/haru/redmine_theme_changer.git)
* [redmine_view_customize](https://github.com/onozaty/redmine-view-customize.git)
* [redmine_wiki_extension](https://github.com/haru/redmine_wiki_extensions.git)
* [redmine_issue_todo_lists](https://github.com/canidas/redmine_issue_todo_lists.git)
* [redmine_code_review](https://github.com/haru/redmine_code_review)
* [redmine_issue_templates](https://github.com/akiko-pusu/redmine_issue_templates)
* [redmine_lightbox2](https://github.com/paginagmbh/redmine_lightbox2.git)

## Docker image used

For build custom docker image you can use any standard redmine docker image. Image name and version set in configuration. By default tested with redmine 4.x image version.
* [redmine](https://hub.docker.com/_/redmine)

## Requirements

* linux 64bit (git, make, wget, gawk, openssl)
* [docker](http://docker.io)
* [dcape](https://github.com/dopos/dcape)
* Git service ([github](https://github.com), [gitea](https://gitea.io)

## Usage

For deploy this project need direct root access to the server

* Fork this repo in your Git service
* Setup deploy hook 
* Press "Test delivery" button in repository web page (config sample will be created in dcape)
* Put data to the config (set CMD_DEPLOY=build, set _CI_HOOK_ENABLED=yes)
* Press "Test delivery" button
* Check build log on cis web service 
* Edit config and set CMD_DEPLOY=up -d --force-recreate (set REDIR_ENTRY=https if need)
* Press "Test delivery" button
* Run in container: `bundle exec rake redmine:plugins:assets RAILS_ENV=production` for user redmine
* Load default redmine database configuration on administrate setting web page
* Set REDMINE_NO_DB_MIGRATE=yes and REDMINE_PLUGINS_MIGRATE set to empty
* Restart redmine and enjoy


## Database load and backup

In Makefile content script for make and load database backup for postgres database.

TODO
Add autimatic create and rotate backup files.

See also: [Deploy setup](https://github.com/dopos/dcape/blob/master/DEPLOY.md) (in Russian)

## License

The MIT License (MIT), see [LICENSE](LICENSE).

2021 Maxim Danilin <zan@whiteants.net>
