default:
  @just --list

# lint rb files with rubocop
lint:
  bundle exec rubocop

# run image_optim from repo
run *ARGS:
  ruby -Ilib bin/image_optim {{ARGS}}

# rspec tests
test:
  bundle exec rspec
