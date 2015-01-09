VAGRANTFILE_API_VERSION = '2'

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.box = 'ubuntu/trusty64'

  config.vm.provision 'shell', :inline => <<-SH
    set -e

    cd /vagrant

    echo 'Install git, node, npm, imagemagick...'
    apt-get install -y git npm nodejs-legacy imagemagick > /dev/null

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
