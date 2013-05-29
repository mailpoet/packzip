# Packzip.
The Wordpress plugin development automation tool.
Packzip is a Ruby/Sinatra app that is able to pack, compress, translate and zip your project.
It also exposes an API that can be used to check version numbers and download packages.

![Packzip](http://www.wysija.com/wp-content/uploads/2013/05/packzip.gif)

# Features.
- Pull from a remote git repository.
- Minify JS files.
- Compress CSS files.
- Pull latest .po files from Transifex.
- Convert .po files to .mo files.
- Output a .zip file.

## System Dependencies.
- [ruby](http://www.ruby-lang.org/en/)
- [bundler](http://gembundler.com/)
- [git](http://git-scm.com/)
- [zip](http://manpages.ubuntu.com/manpages/precise/man1/zip.1.html)
- [transifex-client](http://help.transifex.com/features/client/)

## Setup.
1. Requirements:
You plugin repository should have two branches, dev and master, and the directory structure should follow our [Barebone](https://github.com/Wysija/barebone) structure.

2. Clone Packzip:
```sh
$ git clone git://github.com/Wysija/packzip.git
$ cd packzip
```

3. Add a good username/password and your git repo url to the .env file:
```sh
# .env
USERNAME=admin
PASSWORD=password
GIT_URL="git://github.com/Wysija/barebone.git"
```

4. Initialize your transifex directory, in /tmp/transifex:
```sh
$ cd tmp/transifex
$ tx init
$ tx set --auto-remote  https://www.transifex.com/projects/p/project-name/
```

5. Set the following filter by editing tmp/transifex/.tx/config and pull manually the first time:
```sh
# config
file_filter = project-name-<lang>.po
```
```sh
$ tx pull -a
```

## Deploy.

- Development: the app will use a shotgun/puma local server, running with foreman.
```sh
$ bundle install --without production
$ bundle exec foreman start  -f Procfile.development
```

- Production: the app will use a puma instance listening on unix:///tmp/packzip.sock and running with foreman.
Configure your Apache or Nginx proxy upstream with that socket.
```sh
$ bundle install --without development
$ bundle exec foreman start
```

## API

- Check latest version number:

```ruby
get '/release/check?branch=(dev | master)'
# => x.x.x
```

- Get zip file:

```ruby
get '/release/zip?branch=(dev | master)'
# => zip file stream
```

## Thanks to:
- [Sinatra](http://www.sinatrarb.com/)
- [DataMapper](http://datamapper.org/)
- [Foreman](http://ddollar.github.io/foreman/)
- [Puma](http://puma.io/)

## License.

[MIT](http://opensource.org/licenses/MIT)