<?php

namespace App\Http\Controllers;

use App\Models\Category;
use App\Models\Product;
use App\Models\StockMutation;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class ProductController extends Controller
{
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

        $products   = $query->latest()->paginate(15)->withQueryString();
        $categories = Category::orderBy('name')->get();

        return view('products.index', compact('products', 'categories'));
    }

    public function create()
    {
        $categories = Category::orderBy('name')->get();
        return view('products.create', compact('categories'));
    }

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
                    'notes'          => 'Stok Awal — Produk Baru',
                ]);
            }

            return $product;
        });

        return redirect()->route('products.index')
            ->with('success', "Produk \"{$product->name}\" berhasil ditambahkan.");
    }

    public function edit(Product $product)
    {
        $categories = Category::orderBy('name')->get();
        return view('products.edit', compact('product', 'categories'));
    }

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
                    'notes'          => 'Penyesuaian stok melalui form edit',
                ]);
            }
        });

        return redirect()->route('products.index')
            ->with('success', "Produk \"{$product->name}\" berhasil diperbarui.");
    }

    public function destroy(Product $product)
    {
        $name = $product->name;
        $product->delete();

        return redirect()->route('products.index')
            ->with('success', "Produk \"{$name}\" berhasil dihapus.");
    }
}
