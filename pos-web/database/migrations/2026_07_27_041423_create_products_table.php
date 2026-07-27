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
        Schema::create('products', function (Blueprint $table) {
            $table->id();
            $table->foreignId('category_id')->nullable()->constrained()->nullOnDelete();
            $table->string('name');
            $table->string('sku')->unique()->comment('Kode unik / barcode barang');
            $table->decimal('cost_price', 15, 2)->comment('Harga modal / beli');
            $table->decimal('selling_price', 15, 2)->comment('Harga jual');
            $table->integer('stock')->default(0)->comment('Jumlah stok fisik saat ini');
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('products');
    }
};
