<?php

namespace App\Http\Controllers;

use App\Models\Category;
use App\Models\Product;

class PosController extends Controller
{
    public function index()
    {
        $products   = Product::with('category')->orderBy('name')->get();
        $categories = Category::orderBy('name')->get();

        return view('pos.index', compact('products', 'categories'));
    }
}
