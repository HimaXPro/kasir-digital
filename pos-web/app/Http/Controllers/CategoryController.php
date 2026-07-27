<?php

namespace App\Http\Controllers;

use App\Models\Category;
use Illuminate\Http\Request;

class CategoryController extends Controller
{
    public function index()
    {
        $categories = Category::withCount('products')->orderBy('name')->get();
        return view('categories.index', compact('categories'));
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'name' => 'required|string|max:100|unique:categories,name',
            'slug' => 'nullable|string|max:100|unique:categories,slug',
        ]);

        if (empty($data['slug'])) {
            $data['slug'] = \Illuminate\Support\Str::slug($data['name']);
        }

        Category::create($data);

        return redirect()->route('categories.index')
            ->with('success', "Kategori \"{$data['name']}\" berhasil ditambahkan.");
    }

    public function update(Request $request, Category $category)
    {
        $data = $request->validate([
            'name' => "required|string|max:100|unique:categories,name,{$category->id}",
        ]);

        $category->update(['name' => $data['name'], 'slug' => \Illuminate\Support\Str::slug($data['name'])]);

        return redirect()->route('categories.index')
            ->with('success', "Kategori berhasil diperbarui.");
    }

    public function destroy(Category $category)
    {
        if ($category->products()->count() > 0) {
            return redirect()->route('categories.index')
                ->with('error', "Kategori \"{$category->name}\" tidak bisa dihapus karena masih ada produk di dalamnya.");
        }

        $name = $category->name;
        $category->delete();

        return redirect()->route('categories.index')
            ->with('success', "Kategori \"{$name}\" berhasil dihapus.");
    }
}
