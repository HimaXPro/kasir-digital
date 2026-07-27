<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Product;
use App\Models\StockMutation;
use App\Models\Transaction;
use App\Models\TransactionDetail;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class TransactionController extends Controller
{
    public function store(Request $request)
    {
        $request->validate([
            'items' => 'required|array|min:1',
            'items.*.product_id' => 'required|exists:products,id',
            'items.*.quantity' => 'required|integer|min:1',
            'pay_amount' => 'required|numeric',
            'payment_method' => 'required|in:cash,qris,transfer,debit',
        ]);

        return DB::transaction(function () use ($request) {
            $totalAmount = 0;
            $detailsData = [];
            $stockMutations = [];

            // 1. Hitung total dan validasi ketersediaan stok
            foreach ($request->items as $item) {
                $product = Product::lockForUpdate()->find($item['product_id']);

                if ($product->stock < $item['quantity']) {
                    throw new \Exception("Stok produk {$product->name} tidak mencukupi. Sisa: {$product->stock}");
                }

                $subtotal = $product->selling_price * $item['quantity'];
                $totalAmount += $subtotal;

                // Simpan data detail transaksi
                $detailsData[] = [
                    'product_id' => $product->id,
                    'quantity' => $item['quantity'],
                    'cost_price' => $product->cost_price,
                    'selling_price' => $product->selling_price,
                    'subtotal' => $subtotal,
                ];

                // Data untuk lini masa mutasi stok
                $stockMutations[] = [
                    'product_id' => $product->id,
                    'type' => 'out',
                    'quantity' => $item['quantity'],
                    'cost_price' => $product->cost_price,
                    'selling_price' => $product->selling_price,
                    'reference_type' => 'sale',
                    'created_at' => now(),
                    'updated_at' => now(),
                ];

                // Potong stok barang
                $product->decrement('stock', $item['quantity']);
            }

            $discount = $request->discount_amount ?? 0;
            $grandTotal = $totalAmount - $discount;
            $changeAmount = $request->pay_amount - $grandTotal;

            if ($changeAmount < 0) {
                throw new \Exception('Uang pembayaran kurang.');
            }

            // 2. Simpan Header Transaksi
            $transaction = Transaction::create([
                'invoice_number' => 'INV-' . strtoupper(Str::random(8)),
                'user_id' => Auth::id() ?? 1, // <-- Menggunakan Auth::id()
                'total_amount' => $totalAmount,
                'discount_amount' => $discount,
                'grand_total' => $grandTotal,
                'pay_amount' => $request->pay_amount,
                'change_amount' => $changeAmount,
                'payment_method' => $request->payment_method,
            ]);

            // 3. Simpan Detail Transaksi & Mutasi Stok secara Massal
            foreach ($detailsData as &$detail) {
                $detail['transaction_id'] = $transaction->id;
                $detail['created_at'] = now();
                $detail['updated_at'] = now();
            }
            TransactionDetail::insert($detailsData);

            foreach ($stockMutations as &$mutation) {
                $mutation['notes'] = "Penjualan Invoice: " . $transaction->invoice_number;
            }
            StockMutation::insert($stockMutations);

            return response()->json([
                'success' => true,
                'message' => 'Transaksi berhasil diproses',
                'data' => $transaction->load('transactionDetails.product')
            ], 201);
        });
    }
}
