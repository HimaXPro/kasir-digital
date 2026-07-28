<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Category;
use Illuminate\Http\Request;

class CategoryApiController extends Controller
{
    /**
     * GET /api/categories
     */
    public function index()
    {
        $categories = Category::withCount('products')->orderBy('name')->get();

        return response()->json([
            'success' => true,
            'data'    => $categories,
        ]);
    }

    /**
     * POST /api/categories
     */
    public function store(Request $request)
    {
        $data = $request->validate([
            'name' => 'required|string|max:255|unique:categories,name',
        ]);

        $category = Category::create($data);

        return response()->json([
            'success' => true,
            'message' => "Kategori \"{$category->name}\" berhasil ditambahkan.",
            'data'    => $category,
        ], 201);
    }

    /**
     * PUT /api/categories/{category}
     */
    public function update(Request $request, Category $category)
    {
        $data = $request->validate([
            'name' => "required|string|max:255|unique:categories,name,{$category->id}",
        ]);

        $category->update($data);

        return response()->json([
            'success' => true,
            'message' => "Kategori \"{$category->name}\" berhasil diperbarui.",
            'data'    => $category->fresh(),
        ]);
    }

    /**
     * DELETE /api/categories/{category}
     */
    public function destroy(Category $category)
    {
        $name = $category->name;
        $category->delete();

        return response()->json([
            'success' => true,
            'message' => "Kategori \"{$name}\" berhasil dihapus.",
        ]);
    }
}
