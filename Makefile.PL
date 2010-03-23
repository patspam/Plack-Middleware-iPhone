use inc::Module::Install;

name     'Plack-Middleware-iPhone';
all_from 'lib/Plack/Middleware/iPhone.pm';
author   q{Patrick Donelan <pat@patspam.com>};
license  'perl';
readme_from 'lib/Plack/Middleware/iPhone.pm';

build_requires 'Test::More';

requires Plack;
requires 'Digest::MD5';
requires 'File::Slurp';
requires autodie;
requires 'HTML::DOM';
requires 'HTML::Tidy';

auto_install;

WriteAll;

