# Description

This repo is an attempt to reproduce a very strange bundle build error of the gem `sass-embedded`.

During the building of another project with this gem as a dependency for `dartsass-sprockets` inside a Docker container, while passing `--platform linux/amd64`, we get the following error:

```
342.3 Bundler::HTTPError: Could not download gem from https://rubygems.org/ due to
342.3 underlying error <bad response Forbidden 403
342.3 (https://rubygems.org/gems/sass-embedded-1.77.5-x86_64-linux.gem)>
342.3 /home/circleci/app/vendor/bundle/ruby/3.3.0/gems/bundler-2.4.10/lib/bundler/rubygems_integration.rb:497:in
342.3 /home/circleci/app/vendor/bundle/ruby/3.3.0/gems/bundler-2.4.10/lib/bundler/rubygems_integration.rb:469:in
342.3 /home/circleci/app/vendor/bundle/ruby/3.3.0/gems/bundler-2.4.10/lib/bundler/source/rubygems.rb:484:in
342.3 /home/circleci/app/vendor/bundle/ruby/3.3.0/gems/bundler-2.4.10/lib/bundler/source/rubygems.rb:446:in
342.3 /home/circleci/app/vendor/bundle/ruby/3.3.0/gems/bundler-2.4.10/lib/bundler/source/rubygems.rb:430:in
342.3 /home/circleci/app/vendor/bundle/ruby/3.3.0/gems/bundler-2.4.10/lib/bundler/source/rubygems.rb:158:in
342.3 /home/circleci/app/vendor/bundle/ruby/3.3.0/gems/bundler-2.4.10/lib/bundler/installer/gem_installer.rb:54:in
342.3 /home/circleci/app/vendor/bundle/ruby/3.3.0/gems/bundler-2.4.10/lib/bundler/installer/gem_installer.rb:16:in
342.3 /home/circleci/app/vendor/bundle/ruby/3.3.0/gems/bundler-2.4.10/lib/bundler/installer/parallel_installer.rb:156:in
342.3 /home/circleci/app/vendor/bundle/ruby/3.3.0/gems/bundler-2.4.10/lib/bundler/installer/parallel_installer.rb:147:in
342.3 /home/circleci/app/vendor/bundle/ruby/3.3.0/gems/bundler-2.4.10/lib/bundler/worker.rb:62:in
342.3 /home/circleci/app/vendor/bundle/ruby/3.3.0/gems/bundler-2.4.10/lib/bundler/worker.rb:57:in
342.3 /home/circleci/app/vendor/bundle/ruby/3.3.0/gems/bundler-2.4.10/lib/bundler/worker.rb:54:in
342.3 /home/circleci/app/vendor/bundle/ruby/3.3.0/gems/bundler-2.4.10/lib/bundler/worker.rb:90:in
342.3 `block (2 levels) in create_threads'
342.3
342.3 An error occurred while installing sass-embedded (1.77.5), and Bundler cannot
342.3 continue.
342.3
342.3 In Gemfile:
342.3   dartsass-sprockets was resolved to 3.1.0, which depends on
342.3     sassc-embedded was resolved to 1.77.8, which depends on
342.3       sass-embedded
```

The error is valid: this gem is not available with the suffix `x86_64-linux`, however it is available with the suffix `x86_64-linux-gnu` (and a few additional Linux options). 
 
# How to build

This repo can be built by running:

```bash
./build
```

And if the build is successful,

```bash
docker run -it sass-embedded:latest 
```

