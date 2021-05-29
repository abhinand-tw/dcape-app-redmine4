# dcape-app-redmine Makefile
# the Makefile config and start standart docker redmine image with dcape adaptation config and dirs

SHELL               = /bin/bash
CFG                ?= .env

# Site host
APP_SITE           ?= rm.lan
# Redmine subdirs (plugins, files, tmp, public, db, log ) index for use on dcape 
PRJ_INDEX          ?= rm4
# Name for custom build image
IMAGE_BUILD        ?= redmine_$(PRJ_INDEX)
# Version for custom build image
IMAGE_BUILD_VER    ?= 0.1


# Database name
DB_NAME            ?= redmine_$(PRJ_INDEX)
# Database user name
DB_USER            ?= redmine_$(PRJ_INDEX)
# Database user password
DB_PASS            ?= $(shell < /dev/urandom tr -dc A-Za-z0-9 | head -c14; echo)
# Database dump filename, without extensions (.gz), for import on create (you must use file .gz formant)
DB_SOURCE          ?=


# Docker base image name that use for building custom image
IMAGE_BASE         ?= redmine
# Docker base image tag
IMAGE_BASE_VER     ?= 4.1.3
# Subdirs list for copy to volume and prepare use with dcape, 
# log and files dirs empry and prepare always, don't need insert to SUBDIRS
SUBDIRS            ?= public db plugins tmp
# Redmine user ID for IMAGE_BASE
UID_BASE           ?= 999
# Redmine Group ID for IMAGE_BASE
GUID_BASE          ?= 999 
# Docker-compose project name (container name prefix)
PROJECT_NAME       ?= $(shell basename $$PWD)
# dcape container name prefix
DCAPE_PROJECT_NAME ?= dcape
# dcape network attach to
DCAPE_NET          ?= $(DCAPE_PROJECT_NAME)_default
# dcape postgresql container name
DCAPE_DB           ?= $(DCAPE_PROJECT_NAME)_db_1

#environments for SMTP email configuration
REDMINE_EMAIL_DELIVERY_METHOD = :smtp
REDMINE_EMAIL_ADDRESS         = localhost
REDMINE_EMAIL_PORT            = 25
REDMINE_EMAIL_AUTHENTICATION  = :login
REDMINE_EMAIL_DOMAIN          = localhost
REDMINE_EMAIL_USER_NAME       =
REDMINE_EMAIL_PASSWORD        =

# Docker-compose image tag
DC_VER             ?= 1.28.6
# Container id for prepare subdirs
CONTAINER_ID       = $(shell docker create -v /var/run/docker.sock:/var/run/docker.sock ${IMAGE_BASE}:${IMAGE_BASE_VER})

define CONFIG_DEF
# ------------------------------------------------------------------------------
# Redmine settings

# Site host
APP_SITE=$(APP_SITE)
# Redmine subdirs (plugins, files, tmp, public, db, log ) index use for dcape 
PRJ_INDEX=$(PRJ_INDEX)
# Name for custumise builded image
IMAGE_BUILD=$(IMAGE_BUILD)
# Version
IMAGE_BUILD_VER=$(IMAGE_BUILD_VER)


# Database name
DB_NAME=$(DB_NAME)
# Database user name
DB_USER=$(DB_USER)
# Database user password
DB_PASS=$(DB_PASS)
# Database dump filename for import on create
DB_SOURCE=$(DB_SOURCE)

# Docker details

# Docker base image name that use for building custom image
IMAGE_BASE=$(IMAGE_BASE)
# Docker base image tag
IMAGE_BASE_VER=$(IMAGE_BASE_VER)
# Subdirs list for copy to volume and use with dcape
SUBDIRS=$(SUBDIRS)
# Redmine user ID for IMAGE_BASE
UID_BASE=$(UID_BASE)
# Redmine Group ID for IMAGE_BASE
GUID_BASE=$(GUID_BASE) 

# Docker-compose project name (container name prefix)
PROJECT_NAME=$(PROJECT_NAME)
# dcape network attach to
DCAPE_NET=$(DCAPE_NET)
# dcape postgresql container name
DCAPE_DB=$(DCAPE_DB)

#environments for SMTP email configuration
REDMINE_EMAIL_DELIVERY_METHOD=$(REDMINE_EMAIL_DELIVERY_METHOD)
REDMINE_EMAIL_ADDRESS=$(REDMINE_EMAIL_ADDRESS)
REDMINE_EMAIL_PORT=$(REDMINE_EMAIL_PORT)
REDMINE_EMAIL_AUTHENTICATION=$(REDMINE_EMAIL_AUTHENTICATION)
REDMINE_EMAIL_DOMAIN=$(REDMINE_EMAIL_DOMAIN)
REDMINE_EMAIL_USER_NAME=$(REDMINE_EMAIL_USER_NAME)
REDMINE_EMAIL_PASSWORD=$(REDMINE_EMAIL_PASSWORD)

endef
export CONFIG_DEF

-include $(CFG)
export

.PHONY: all $(CFG) start start-hook stop update up reup down docker-wait db-create db-drop psql dc help

all: help


# ------------------------------------------------------------------------------
# webhook commands
start: db-create up

start-hook: db-create reup

stop: down

update: reup

db-dump: db-dump

# ------------------------------------------------------------------------------
# docker commands
## старт контейнеров
up:
up: CMD=up -d
up: dc

## рестарт контейнеров
reup: 
reup: CMD=up --force-recreate -d
reup: subdirs dc

## остановка и удаление всех контейнеров
down:
down: CMD=down -v
down: dc

# Wait for postgresql container start
docker-wait:
	@echo -n "Checking PG is ready..."
	@until [[ `docker inspect -f "{{.State.Health.Status}}" $$DCAPE_DB` == healthy ]] ; do sleep 1 ; echo -n "." ; done
	@echo "Ok"

# ------------------------------------------------------------------------------
# DB operations

# Database import script
# DCAPE_DB_DUMP_DEST must be set in pg container
define IMPORT_SCRIPT
[[ "$$DCAPE_DB_DUMP_DEST" ]] || { echo "DCAPE_DB_DUMP_DEST not set. Exiting" ; exit 1 ; } ; \
DB_NAME="$$1" ; DB_USER="$$2" ; DB_PASS="$$3" ; DB_SOURCE="$$4" ; \
dbsrc=$$DCAPE_DB_DUMP_DEST/$$DB_SOURCE.gz ; \
if [ -f $$dbsrc ] ; then \
  echo "Dump file $$dbsrc found, restoring database..." ; \
# use pg_restore, but psql load 100% cpu and if use psql --echo-all - some times (random) have error - out memory, even when memory (RAM,SWAP,HDD) free big size
  pg_restore -d $$DB_NAME -U $$DB_USER $$dbsrc || echo "error load dump" ; \
  sleep 2 ; \
  psql -e -U $$DB_USER -d $$DB_NAME -c "CREATE TABLE make_import ( name varchar(10));" ; \
  echo "Pg_restore finish. If pg_restore finish with critical error - delete make_import table manual" ; \
else \
  echo "Dump file $$dbsrc not found" ; \
  exit 2 ; \
fi
endef
export IMPORT_SCRIPT

define EXPORT_SCRIPT
[[ "$$DCAPE_DB_DUMP_DEST" ]] || { echo "DCAPE_DB_DUMP_DEST not set. Exiting" ; exit 1 ; } ; \
DB_NAME="$$1" ; DB_USER="$$2" ; APP_SITE="$$3" ; \
echo "Backup Redmine database: $$DB_NAME to file:" ; \
dt=$$(date +%y%m%d) ; \
dest=$$DCAPE_DB_DUMP_DEST/$$APP_SITE-$$DB_NAME-dump-$${dt}.gz ; \
echo -n $${dest}... ; \
[ -f $$dest ] && { echo "File exist. Skip" ; continue ; } ; \
pg_dump -v -U $$DB_USER -Fc $$DB_NAME > $$dest || echo "error create dump" ;
echo Done
endef
export EXPORT_SCRIPT

# create user, db and load dump
# check DATABASE exist and set of docker-compose.yml variable via .env
db-create: docker-wait
	@echo "*** $@ ***" ; \
	docker exec -i $$DCAPE_DB psql -U postgres -c "CREATE USER \"$$DB_USER\" WITH PASSWORD '$$DB_PASS';" || true ; \
	docker exec -i $$DCAPE_DB psql -U postgres -c "CREATE DATABASE \"$$DB_NAME\" OWNER \"$$DB_USER\";" || db_exists=1 ; \
	docker exec -i $$DCAPE_DB psql -U postgres -c "GRANT ALL PRIVILEGES ON DATABASE $$DB_NAME to $$DB_USER" ; \
	if [[ ! "$$db_exists" ]] ; then \
          if [[ "$$DB_SOURCE" ]] ; then \
            echo "$$IMPORT_SCRIPT" | docker exec -i $$DCAPE_DB bash -s - $$DB_NAME $$DB_USER $$DB_PASS $$DB_SOURCE \
            && docker exec -i $$DCAPE_DB psql -U postgres -c "COMMENT ON DATABASE \"$$DB_NAME\" IS 'SOURCE $$DB_SOURCE';" \
            || true ; \
          fi  \
        fi

## drop database and user
db-drop: docker-wait
	@echo "*** $@ ***"
	@docker exec -i $$DCAPE_DB psql -U postgres -c "DROP DATABASE \"$$DB_NAME\";" || true
	@docker exec -i $$DCAPE_DB psql -U postgres -c "DROP USER \"$$DB_USER\";" || true

## dump redmine database to file
db-dump: docker-wait
	@echo "*** $@ ***"
	@echo "$$EXPORT_SCRIPT" | docker exec -i --user root $$DCAPE_DB bash -s - $$DB_NAME $$DB_USER $$APP_SITE

# prepare subdirectory from IMAGE_BASE to use in permanent with dcape environment
subdirs:
	@echo "*** $@ ***" 
	@mkdir -p ../../data/redmine_$$PRJ_INDEX
	@for dir in $$SUBDIRS; do \
	  docker cp $(CONTAINER_ID):/usr/src/redmine/$$dir ../../data/redmine_$(PRJ_INDEX)/ ;\
	done
	@mkdir -p ../../data/redmine_$$PRJ_INDEX/files
	@chown -R $$UID_BASE:$$GUID_BASE ../../data/redmine_$(PRJ_INDEX)
	@mkdir -p ../../log/redmine_$(PRJ_INDEX)/log
	@chown -R $$UID_BASE:$$GUID_BASE ../../log/redmine_$(PRJ_INDEX)

#	@docker cp $(CONTAINER_ID):/usr/src/redmine/tmp ../../data/redmine_rm4




# ------------------------------------------------------------------------------
# $$PWD используется для того, чтобы текущий каталог был доступен в контейнере по тому же пути
# и относительные тома новых контейнеров могли его использовать
## run docker-compose
dc: docker-compose.yml
	@docker run --rm  \
         -v /var/run/docker.sock:/var/run/docker.sock \
         -v $$PWD:$$PWD \
         -w $$PWD \
         docker/compose:$(DC_VER) \
         -p $$PROJECT_NAME \
         $(CMD)


$(CFG):
	@[ -f $@ ] || { echo "$$CONFIG_DEF" > $@ ; echo "Warning: Created default $@" ; }

# ------------------------------------------------------------------------------

## List Makefile targets
help:
	@grep -A 1 "^##" Makefile | less

##
## Press 'q' for exit
##
