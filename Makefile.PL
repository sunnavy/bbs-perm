use strict;
use inc::Module::Install 0.46;
name 'BBS-Perm';
license 'perl';
all_from 'lib/BBS/Perm.pm';
readme_from 'lib/BBS/Perm.pm';
requires Encode => 0;
requires 'UNIVERSAL::require' => 0;
requires 'UNIVERSAL::moniker' => 0;
requires Gtk2 => '1.144';
requires 'Gnome2::Vte' => '0.07';
requires 'Regexp::Common' => '2.120';
requires 'IP::QQWry' => '0.0.13'; 
requires Expect => 0;
requires 'File::Slurp' => 0;
requires 'File::HomeDir' => 0;

requires( YAML => 0.35 ) unless can_use('YAML::Syck' => 0.71);

no_index directory => 't';
no_index directory => 'xt';

install_script('bin/bbs-perm');
install_script('bin/bbs-perm-agent');
install_script('bin/bbs-perm-config');

auto_install;

tests('t/*.t');
recursive_author_tests('xt/');

WriteAll;

