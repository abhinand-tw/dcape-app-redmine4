ARG IMAGE_BASE
ARG IMAGE_BASE_VER
FROM $IMAGE_BASE:$IMAGE_BASE_VER
MAINTAINER elatica7@gmail.com 

ENV VER=20210605

# install plugins
# install dependencies
RUN set -eux; \
	apt-get update; \
	apt-get install -y --no-install-recommends \
	make \
	gcc \
	g++ \ 
	nodejs ; \
	rm -rf /var/lib/apt/lists/*

# download plugins and install need gems
RUN set -x \
	# add plugins for redmine
	&& cd /usr/src/redmine/plugins \
	&& git clone https://github.com/jouve/sidebar_hide \
	&& git clone https://github.com/YujiSoftware/redmine-fixed-header.git redmine_fixed_header \
	&& git clone https://github.com/mikitex70/redmine_drawio.git \
	&& git clone https://github.com/tkusukawa/redmine_wiki_lists.git \
	&& git clone https://github.com/haru/redmine_theme_changer.git \
	&& git clone https://github.com/onozaty/redmine-view-customize.git view_customize \
	&& git clone https://github.com/haru/redmine_wiki_extensions.git \
	&& git clone https://github.com/canidas/redmine_issue_todo_lists.git \
	&& git clone https://github.com/haru/redmine_code_review \
	&& git clone https://github.com/akiko-pusu/redmine_issue_templates \
	&& git clone https://github.com/paginagmbh/redmine_lightbox2.git \
	&& git clone https://github.com/hicknhack-software/redmine_hourglass \
	# remove string - "gem 'saas'" from Gemfile, for delete dependency error version >= 0, we have saas '~> 3.4.15'
	&& sed -i '/sass/d' redmine_hourglass/Gemfile \
	# add themes for redmine
	&& cd /usr/src/redmine/public/themes \
	# gitmike
	&& git clone https://github.com/makotokw/redmine-theme-gitmike.git gitmike \
	&& cd ../.. \
	#     && rm plugins/easy_wbs/Gemfile \
	&& bundle update \
	&& bundle install --local --without development test 


