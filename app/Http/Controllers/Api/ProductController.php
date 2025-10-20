<?php

namespace App\Http\Controllers\Api;

use App\Http\Requests\ProductRequest;
use App\Http\Resources\ProductResource;
use App\Models\Brand;
use App\Models\Categories;
use App\Models\Product;
use App\Http\Controllers\Controller;
use Illuminate\Http\Request;

class ProductController extends Controller
{
    /**
     * Display a listing of the resource.
     */
    public function index()
    {
        $paginate = request()->query("paginate");
        $search = request()->query("search");
        $excluding = explode(",", request()->query("excluding"));
        return ProductResource::collection(Product::where("name", "like", "%{$search}%")
            ->whereNotIn("id", $excluding)
            ->paginate($paginate));
    }

    /**
     * Show the form for creating a new resource.
     */
    public function create()
    {
        //
    }

    /**
     * Store a newly created resource in storage.
     */
    public function store(Request $request)
    {
        Product::create($request->all());
        return $this->index();
    }

    /**
     * Display the specified resource.
     */
    public function show($product_url)
    {
        return new ProductResource(Product::where("url", $product_url)->first());
        // return Product::where("url", $product_url)->first();
    }

    /**
     * Show the form for editing the specified resource.
     */
    public function edit(Product $product)
    {
        //
    }

    /**
     * Update the specified resource in storage.
     */
    public function update(ProductRequest $request, $product_url)
    {
        $product = Product::where("url", $product_url)->first();
        $validated = $request->validated();
        $product->update($validated);
        return $this->index();
    }

    /**
     * Remove the specified resource from storage.
     */
    public function destroy(Product $product)
    {
        $product->delete();
        return $this->index();
    }
}
