use inc::Module::Install;

name           'Parallel-SubArray';
all_from       'lib/Parallel/SubArray.pm';
license        'bsd';
requires       'Storable'   => 2.18;
test_requires  'Test::More' => 0.86;

WriteAll;
