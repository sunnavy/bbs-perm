use strict;
use inc::Module::Install 0.46;
name 'BBS-Perm';
license 'perl';
all_from 'lib/BBS/Perm.pm';
author 'sunnavy <sunnavy@gmail.com>';
requires version => 0;
requires Encode => 0;
requires 'UNIVERSAL::require' => 0;
requires 'UNIVERSAL::moniker' => 0;
requires Gtk2 => '1.144';
requires 'Gnome2::Vte' => '0.07';
requires 'Regexp::Common' => '2.120';
requires 'IP::QQWry' => '0.0.13'; 
requires Expect => 0;
requires 'File::Slurp' => 0;

requires( YAML => 0.35 ) unless can_use('YAML::Syck' => 0.71);

build_requires 'Test::More' => 0;

no_index directory => 'examples';

auto_install;

WriteAll;

