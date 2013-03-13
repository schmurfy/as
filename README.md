

# Continuous integration ([![Build Status](https://secure.travis-ci.org/schmurfy/as.png)](http://travis-ci.org/schmurfy/as))

This gem is tested against these ruby by travis-ci.org:

- mri 1.9.3
- mri 2.0.0

# What is this gem ?
This gem is an ActiveSync server implementation in Ruby, currently only the contacts part of the api is implemented.

# Usage

Have a look at the example folder, this is a standard rack application but the push support
requires eventmachine, to run it:
```bash
$ bundle
$ cd example
$ bundle exec thin start
```

You can then connect with ssl disabled and "user" as username with "pass" as password.
(you can use nginx as frontend to enable https if you want)


# Supported clients
- Android 4.0.3
- Android 2.2

# Setting up development environment

```bash
# clone the repository and:
$ bundle
$ bundle exec guard
```

the tests will run when a file changed, if only want to run all tests once:

```bash
$ bundle exec rake
```
