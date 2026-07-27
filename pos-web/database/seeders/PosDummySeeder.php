<?php

namespace Database\Seeders;

use App\Models\Category;
use App\Models\Product;
use App\Models\StockMutation;
use App\Models\Transaction;
use App\Models\TransactionDetail;
use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Str;

class PosDummySeeder extends Seeder
{
    public function run(): void
    {
        // 1. Pastikan Ada User Default
        $user = User::firstOrCreate(
            ['email' => 'admin@pos.com'],
            [
                'name' => 'Admin Kasir',
                'password' => bcrypt('password123'),
            ]
        );

        // 2. Buat Kategori Dummy
        $makanan = Category::create(['name' => 'Makanan', 'slug' => 'makanan']);
        $minuman = Category::create(['name' => 'Minuman', 'slug' => 'minuman']);

        // 3. Buat Produk Dummy
        $products = [
            [
                'category_id' => $makanan->id,
                'name' => 'Nasi Goreng Spesial',
                'sku' => 'PRD-001',
                'cost_price' => 12000,
                'selling_price' => 20000,
                'stock' => 50,
            ],
            [
                'category_id' => $makanan->id,
                'name' => 'Mie Goreng Seafood',
                'sku' => 'PRD-002',
                'cost_price' => 15000,
                'selling_price' => 25000,
                'stock' => 40,
            ],
            [
                'category_id' => $minuman->id,
                'name' => 'Es Teh Manis',
                'sku' => 'PRD-003',
                'cost_price' => 2000,
                'selling_price' => 5000,
                'stock' => 100,
            ],
            [
                'category_id' => $minuman->id,
                'name' => 'Kopi Latte',
                'sku' => 'PRD-004',
                'cost_price' => 8000,
                'selling_price' => 18000,
                'stock' => 30,
            ],
        ];

        $createdProducts = [];
        foreach ($products as $prod) {
            $product = Product::create($prod);
            $createdProducts[] = $product;

            // Catat Mutasi Stok Masuk Awal (Restock/Modal)
            StockMutation::create([
                'product_id' => $product->id,
                'type' => 'in',
                'quantity' => $product->stock,
                'cost_price' => $product->cost_price,
                'selling_price' => $product->selling_price,
                'reference_type' => 'supplier_restock',
                'notes' => 'Stok Awal dari Supplier',
                'created_at' => now()->subDays(5),
            ]);
        }

        // 4. Buat Simulasi Transaksi Penjualan Dummy (Dalam 3 Hari Terakhir)
        for ($i = 1; $i <= 5; $i++) {
            $transactionDate = now()->subDays(rand(0, 2)); // Tanggal acak 0-2 hari lalu
            $item1 = $createdProducts[array_rand($createdProducts)];
            $item2 = $createdProducts[array_rand($createdProducts)];

            $qty1 = rand(1, 3);
            $qty2 = rand(1, 2);

            $subtotal1 = $item1->selling_price * $qty1;
            $subtotal2 = $item2->selling_price * $qty2;
            $totalAmount = $subtotal1 + $subtotal2;

            // Simpan Transaksi
            $transaction = Transaction::create([
                'invoice_number' => 'INV-' . strtoupper(Str::random(8)),
                'user_id' => $user->id,
                'total_amount' => $totalAmount,
                'discount_amount' => 0,
                'grand_total' => $totalAmount,
                'pay_amount' => $totalAmount + 10000,
                'change_amount' => 10000,
                'payment_method' => 'cash',
                'created_at' => $transactionDate,
                'updated_at' => $transactionDate,
            ]);

            // Detail Item 1
            TransactionDetail::create([
                'transaction_id' => $transaction->id,
                'product_id' => $item1->id,
                'quantity' => $qty1,
                'cost_price' => $item1->cost_price,
                'selling_price' => $item1->selling_price,
                'subtotal' => $subtotal1,
                'created_at' => $transactionDate,
            ]);

            // Detail Item 2
            TransactionDetail::create([
                'transaction_id' => $transaction->id,
                'product_id' => $item2->id,
                'quantity' => $qty2,
                'cost_price' => $item2->cost_price,
                'selling_price' => $item2->selling_price,
                'subtotal' => $subtotal2,
                'created_at' => $transactionDate,
            ]);

            // Catat Mutasi Stok Keluar Item 1
            StockMutation::create([
                'product_id' => $item1->id,
                'type' => 'out',
                'quantity' => $qty1,
                'cost_price' => $item1->cost_price,
                'selling_price' => $item1->selling_price,
                'reference_type' => 'sale',
                'notes' => 'Penjualan Invoice: ' . $transaction->invoice_number,
                'created_at' => $transactionDate,
            ]);

            // Catat Mutasi Stok Keluar Item 2
            StockMutation::create([
                'product_id' => $item2->id,
                'type' => 'out',
                'quantity' => $qty2,
                'cost_price' => $item2->cost_price,
                'selling_price' => $item2->selling_price,
                'reference_type' => 'sale',
                'notes' => 'Penjualan Invoice: ' . $transaction->invoice_number,
                'created_at' => $transactionDate,
            ]);

            // Potong Stok
            $item1->decrement('stock', $qty1);
            $item2->decrement('stock', $qty2);
        }
    }
}
