FROM ghcr.io/phillmv/arquivo-install:latest
ENV RUBYGEMS_VERSION=2.7.0
ENV LC_ALL C.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US.UTF-8

RUN cd /arquivo && git pull
RUN cd /arquivo && bundle && yarn --frozen-lockfile
RUN cd /arquivo && bundle exec rails db:setup
RUN cd /arquivo && bundle exec rails assets:precompile
