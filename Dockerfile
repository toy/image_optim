FROM rhardih/image_optim_pack

RUN apk --update add ruby ruby-irb

RUN echo -e 'install: --no-document\nupdate: --no-document' > "$HOME/.gemrc"

RUN gem install image_optim
