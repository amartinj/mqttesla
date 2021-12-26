FROM ruby:3.1-rc-alpine

RUN apk update
RUN apk add git
RUN apk add build-base

RUN bundle config --global frozen 1

COPY Gemfile Gemfile.lock /
RUN bundle config set --local without 'development test'
RUN bundle install

COPY main.rb /
COPY lib /lib

CMD ["bundle", "exec", "ruby", "/main.rb"]