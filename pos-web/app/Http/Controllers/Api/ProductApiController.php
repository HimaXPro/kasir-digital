<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Category;
use App\Models\Product;
use App\Models\StockMutation;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class ProductApiController extends Controller
{
    /**
     * GET /api/products
     * Mendukung ?search=&category_id=&per_page=
     */
    public function index(Request $request)
    {
        $query = Product::with('category');

        if ($request->filled('search')) {
            $query->where(function ($q) use ($request) {
                $q->where('name', 'like', "%{$request->search}%")
                  ->orWhere('sku', 'like', "%{$request->search}%");
            });
        }

        if ($request->filled('category_id')) {
            $query->where('category_id', $request->category_id);
        }

        // Untuk POS screen, ambil semua (tanpa paginasi). Untuk manajemen produk, paginate.
        if ($request->boolean('all')) {
            $products = $query->orderBy('name')->get();
            return response()->json(['success' => true, 'data' => $products]);
        }

        $products = $query->latest()->paginate($request->integer('per_page', 15));

        return response()->json([
            'success' => true,
            'data'    => $products->items(),
            'meta'    => [
                'current_page' => $products->currentPage(),
                'last_page'    => $products->lastPage(),
                'per_page'     => $products->perPage(),
                'total'        => $products->total(),
            ],
        ]);
    }

    /**
     * POST /api/products
     */
    public function store(Request $request)
    {
        $data = $request->validate([
            'category_id'   => 'nullable|exists:categories,id',
            'name'          => 'required|string|max:255',
            'sku'           => 'required|string|max:100|unique:products,sku',
            'cost_price'    => 'required|numeric|min:0',
            'selling_price' => 'required|numeric|min:0',
            'stock'         => 'required|integer|min:0',
        ]);

        $product = DB::transaction(function () use ($data) {
            $product = Product::create($data);

            if ($data['stock'] > 0) {
                StockMutation::create([
                    'product_id'     => $product->id,
                    'type'           => 'in',
                    'quantity'       => $data['stock'],
                    'cost_price'     => $data['cost_price'],
                    'selling_price'  => $data['selling_price'],
                    'reference_type' => 'initial_stock',
                    'notes'          => 'Stok Awal — Ditambahkan via Mobile App',
                ]);
            }

            return $product->load('category');
        });

        return response()->json([
            'success' => true,
            'message' => "Produk \"{$product->name}\" berhasil ditambahkan.",
            'data'    => $product,
        ], 201);
    }

    /**
     * PUT /api/products/{product}
     */
    public function update(Request $request, Product $product)
    {
        $data = $request->validate([
            'category_id'   => 'nullable|exists:categories,id',
            'name'          => 'required|string|max:255',
            'sku'           => "required|string|max:100|unique:products,sku,{$product->id}",
            'cost_price'    => 'required|numeric|min:0',
            'selling_price' => 'required|numeric|min:0',
            'stock'         => 'required|integer|min:0',
        ]);

        DB::transaction(function () use ($product, $data) {
            $oldStock = $product->stock;
            $newStock = (int) $data['stock'];

            $product->update($data);

            if ($newStock !== $oldStock) {
                $diff = $newStock - $oldStock;
                StockMutation::create([
                    'product_id'     => $product->id,
                    'type'           => $diff > 0 ? 'in' : 'out',
                    'quantity'       => abs($diff),
                    'cost_price'     => $data['cost_price'],
                    'selling_price'  => $data['selling_price'],
                    'reference_type' => 'adjustment',
                    'notes'          => 'Penyesuaian stok via Mobile App',
                ]);
            }
        });

        return response()->json([
            'success' => true,
            'message' => "Produk \"{$product->name}\" berhasil diperbarui.",
            'data'    => $product->fresh()->load('category'),
        ]);
    }

    /**
     * DELETE /api/products/{product}
     */
    public function destroy(Product $product)
    {
        $name = $product->name;
        $product->delete();

        return response()->json([
            'success' => true,
            'message' => "Produk \"{$name}\" berhasil dihapus.",
        ]);
    }
}
