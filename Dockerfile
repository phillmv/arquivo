# syntax = docker/dockerfile:1

# Make sure RUBY_VERSION matches the Ruby version in .ruby-version and Gemfile
ARG RUBY_VERSION=3.2.2
FROM registry.docker.com/library/ruby:$RUBY_VERSION-slim as base

# Rails app lives here
WORKDIR /arquivo

# Set production environment
ENV RAILS_ENV="production" \
    BUNDLE_WITHOUT="development" \
    BUNDLE_DEPLOYMENT="1"

# Update gems and bundler
RUN gem update --system --no-document && \
    gem install -N bundler


# Throw-away build stages to reduce size of final image
FROM base as prebuild

# Install packages needed to build gems and node modules
RUN --mount=type=cache,id=dev-apt-cache,sharing=locked,target=/var/cache/apt \
    --mount=type=cache,id=dev-apt-lib,sharing=locked,target=/var/lib/apt \
    apt-get update -qq && \
    apt-get install --no-install-recommends -y build-essential curl git node-gyp pkg-config python-is-python3 openssh-client


FROM prebuild as install-node
# FROM prebuild as node

# Install JavaScript dependencies
ARG NODE_VERSION=18.16.0
ARG YARN_VERSION=1.22.4
ENV PATH=/usr/local/node/bin:$PATH
RUN curl -sL https://github.com/nodenv/node-build/archive/master.tar.gz | tar xz -C /tmp/ && \
    /tmp/node-build-master/bin/node-build "${NODE_VERSION}" /usr/local/node && \
    npm install -g yarn@$YARN_VERSION && \
    rm -rf /tmp/node-build-master


FROM install-node as install-node-modules
# Copy application code
## Contrary to the template, here we copy the app code *before* fetching the gems
## and running yarn install because our repo vendors these dependencies; if we copy
## the app code *after* installing deps we'll then overwrite these folders.
COPY --link package.json yarn.lock .
COPY --link node_modules ./node_modules

# Install node modules
RUN --mount=type=cache,id=bld-yarn-cache,target=/root/.yarn \
    YARN_CACHE_FOLDER=/root/.yarn yarn install --frozen-lockfile

FROM install-node-modules as install-gems
## Stage commented out to handle the need for npm when precompiling assets
# FROM prebuild as build

# Install application gems
## Contrary to the template, we avoid setting up the run mount cached directory,
## because we already have a `vendor` folder we copied above, when we copied over
## our application code.

COPY --link Gemfile Gemfile.lock .
COPY --link vendor ./vendor

RUN bundle config set app_config .bundle && \
    bundle config set path vendor && \
    bundle install --local && \
    bundle clean

# Copy node modules
## if we're in one big build section, we don't need this line:
## I suspect the idea is that in the 7.1 world you aren't using npm to build stuff
## so you can just copy the node modules from the node build stage?
# COPY --from=node /rails/node_modules /rails/node_modules

FROM install-gems as build

COPY --link . .
# In install-gems my expectation is that it only has the vendor & node_modules folders
# typing this out maybe i should mount the folder as cache.
COPY --from=install-gems /arquivo .

# Precompile bootsnap code for faster boot times
RUN bundle exec bootsnap precompile --gemfile
RUN bundle exec bootsnap precompile app/ lib/

# Adjust binfiles to be executable on Linux
RUN chmod +x bin/*

# Precompiling assets for production without requiring secret RAILS_MASTER_KEY
# NODE_OPTIONS is a workaround for https://stackoverflow.com/questions/69394632/webpack-build-failing-with-err-ossl-evp-unsupported/69476335#69476335
ENV NODE_OPTIONS="--openssl-legacy-provider"
RUN SECRET_KEY_BASE=DUMMY ./bin/rails assets:precompile

# ---- END STAGES -----

FROM build as development
RUN useradd rails --create-home --shell /bin/bash && \
    mkdir /data && \
    chown -R rails:rails db log storage tmp public /data


# in development, we don't want half the files to be owned by root, so we copy-chown it:
COPY --from=build --chown=rails:rails /arquivo /arquivo

# because in the development stage, the copying step happens after the useradd,
# we have to recreate the symlink:
# (for some reason, rails:rails doesn't the permission to rm storage, which is confusing
# since we just chowned it.)
RUN rm -rf /arquivo/storage && \
    ln -s /data/storage /arquivo/storage && \
    chown -R rails:rails /arquivo/storage

USER rails:rails
# in development, we want every gem
ENV BUNDLE_WITHOUT=
ENV BUNDLE_DEPLOYMENT=

## install packages needed for development
RUN bundle install --local

# temporary hack to handle git config options during test run
RUN git config --global user.email "you@example.com" && \
    git config --global user.name "Your Name"

RUN SECRET_KEY_BASE=DUMMY ./bin/rails assets:precompile RAILS_ENV=test

# Deployment options
ENV DATABASE_URL="sqlite3:///data/database.sqlite3" \
    RAILS_LOG_TO_STDOUT="1" \
    RAILS_SERVE_STATIC_FILES="true"

# Entrypoint prepares the database.
ENTRYPOINT ["/arquivo/bin/docker-entrypoint"]

# Start the server by default, this can be overwritten at runtime
EXPOSE 3000
VOLUME /data
CMD ["./bin/rails", "server"]

# ---------------

# Final stage for app image
FROM base as final

# Install packages needed for deployment
RUN --mount=type=cache,id=dev-apt-cache,sharing=locked,target=/var/cache/apt \
    --mount=type=cache,id=dev-apt-lib,sharing=locked,target=/var/lib/apt \
    apt-get update -qq && \
    apt-get install --no-install-recommends -y curl git openssh-client libsqlite3-0

# Copy built artifacts: gems, application
COPY --from=build /usr/local/bundle /usr/local/bundle
COPY --from=build /arquivo /arquivo

# Run and own only the runtime files as a non-root user for security
RUN useradd rails --create-home --shell /bin/bash && \
    mkdir /data && \
    rm -rf /arquivo/storage && \
    ln -s /data/storage /arquivo/storage && \
    chown -R rails:rails db log storage tmp public /data
USER rails:rails

# Deployment options
ENV DATABASE_URL="sqlite3:///data/production.sqlite3" \
    RAILS_LOG_TO_STDOUT="1" \
    RAILS_SERVE_STATIC_FILES="true"

# temporary hack to handle git config options during test run
RUN git config --global user.email "you@example.com" && \
    git config --global user.name "Your Name"

# Entrypoint prepares the database.
ENTRYPOINT ["/arquivo/bin/docker-entrypoint"]

# Start the server by default, this can be overwritten at runtime
EXPOSE 3000
VOLUME /data
CMD ["./bin/rails", "server"]
