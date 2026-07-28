<?php
require 'vendor/autoload.php';

$c = \Carbon\Carbon::now();
echo 'Now            : ' . $c . PHP_EOL;
echo 'dayOfWeek      : ' . $c->dayOfWeek . ' (0=Sun,1=Mon,...,6=Sat)' . PHP_EOL;
echo 'isSunday       : ' . ($c->isSunday() ? 'YA' : 'tidak') . PHP_EOL;
echo 'monday()       : ' . $c->copy()->monday() . PHP_EOL;
echo 'sunday()       : ' . $c->copy()->sunday() . PHP_EOL;
echo 'startOfWeek()  : ' . $c->copy()->startOfWeek() . PHP_EOL;
echo 'endOfWeek()    : ' . $c->copy()->endOfWeek() . PHP_EOL;
