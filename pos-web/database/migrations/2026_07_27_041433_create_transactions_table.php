<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('transactions', function (Blueprint $table) {
            $table->id();
            $table->string('invoice_number')->unique();
            $table->foreignId('user_id')->comment('Kasir yang melayani')->constrained();
            $table->decimal('total_amount', 15, 2)->comment('Total belanja sebelum diskon');
            $table->decimal('discount_amount', 15, 2)->default(0);
            $table->decimal('grand_total', 15, 2)->comment('Total yang harus dibayar');
            $table->decimal('pay_amount', 15, 2)->comment('Jumlah uang dari pembeli');
            $table->decimal('change_amount', 15, 2)->comment('Uang kembalian');
            $table->enum('payment_method', ['cash', 'qris', 'transfer', 'debit'])->default('cash');
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('transactions');
    }
};
