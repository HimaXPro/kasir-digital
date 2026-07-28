<?php
require __DIR__ . '/vendor/autoload.php';
$app = require __DIR__ . '/bootstrap/app.php';
$app->make(\Illuminate\Contracts\Console\Kernel::class)->bootstrap();

use Carbon\Carbon;
use App\Models\StockMutation;

$now = Carbon::now();
echo 'Timezone: ' . $now->timezone->getName() . PHP_EOL;
echo 'Now     : ' . $now . PHP_EOL;
echo 'dayOfWeek: ' . $now->dayOfWeek . ' (0=Sun, 1=Mon, ..., 6=Sat)' . PHP_EOL;
echo PHP_EOL;

$start = $now->copy()->startOfWeek();
$end   = $now->copy()->endOfWeek();
echo 'startOfWeek() : ' . $start . PHP_EOL;
echo 'endOfWeek()   : ' . $end . PHP_EOL;
echo PHP_EOL;

$inQty = StockMutation::where('type', 'in')
    ->whereBetween('created_at', [$start, $end])
    ->sum('quantity');
$outQty = StockMutation::where('type', 'out')
    ->whereBetween('created_at', [$start, $end])
    ->sum('quantity');

echo "Weekly IN  (with startOfWeek/endOfWeek) : {$inQty} unit\n";
echo "Weekly OUT (with startOfWeek/endOfWeek) : {$outQty} unit\n";
echo PHP_EOL;

// Manual range: Mon 21 Jul - Sun 27 Jul
$manStart = Carbon::parse('2026-07-21 00:00:00');
$manEnd   = Carbon::parse('2026-07-27 23:59:59');
$inMan  = StockMutation::where('type','in')->whereBetween('created_at',[$manStart,$manEnd])->sum('quantity');
$outMan = StockMutation::where('type','out')->whereBetween('created_at',[$manStart,$manEnd])->sum('quantity');
echo "Manual range (21-27 Jul) IN  : {$inMan}\n";
echo "Manual range (21-27 Jul) OUT : {$outMan}\n";
