# frozen_string_literal: true

Vagrant.configure('2') do |config|
  config.vm.box = 'ubuntu/precise64'

  config.vm.provision 'shell', :inline => <<-SH
    set -e

    cd /vagrant

    echo 'apt-get update...'
    apt-get update > /dev/null

    echo 'Install git, imagemagick, ruby1.9.1-dev...'
    apt-get install -y git npm imagemagick ruby1.9.1-dev > /dev/null

    echo 'Install node, npm...'
    curl -sL https://deb.nodesource.com/setup | sudo bash - > /dev/null
    sudo apt-get install -y nodejs > /dev/null

    echo 'Update rubygems...'
    REALLY_GEM_UPDATE_SYSTEM=x gem update --system > /dev/null

    echo 'Install bundler...'
    gem install bundler > /dev/null

    echo 'Install svgo...'
    npm install -g -q svgo > /dev/null

    echo 'Install pngout...'
    curl -s \
      'http://static.jonof.id.au/dl/kenutils/pngout-20130221-linux.tar.gz' | \
      tar -xz -C /usr/local/bin --strip-components 2 \
      --wildcards '*/x86_64/pngout'

    echo 'Bundle...'
    bundle install --jobs=3 --quiet
    bundle list
  SH
end
