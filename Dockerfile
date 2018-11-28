FROM ruby:latest

ENV LANG=C.UTF-8
WORKDIR /usr/src/hiki

COPY . .
RUN bundle install --deployment --without development test --quiet

VOLUME ["/usr/src/hiki/data"]
ENV RACK_ENV=production
EXPOSE 9292

COPY hikiconf.rb.docker hikiconf.rb

ENTRYPOINT ["bundle", "exec"]
CMD ["rackup"]
