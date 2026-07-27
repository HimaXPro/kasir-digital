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
        Schema::create('stock_mutations', function (Blueprint $table) {
            $table->id();
            $table->foreignId('product_id')->constrained()->cascadeOnDelete();
            $table->enum('type', ['in', 'out'])->comment('in = stok masuk, out = stok keluar');
            $table->integer('quantity');
            $table->decimal('cost_price', 15, 2)->comment('Harga modal barang saat mutasi terjadi');
            $table->decimal('selling_price', 15, 2)->default(0)->comment('Harga jual saat mutasi (jika penjualan)');
            $table->string('reference_type')->nullable()->comment('Contoh: sale, supplier_restock, adjustment');
            $table->text('notes')->nullable()->comment('Catatan tambahan atau nomor invoice');
            $table->timestamps(); // created_at digunakan sebagai penanda waktu di timeline
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('stock_mutations');
    }
};
