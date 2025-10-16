<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\ProductController;

Route::middleware(['auth:sanctum'])->get('/user', function (Request $request) {
    return $request->user();
});

Route::get('/hello', function () {
    return response()->json(['message' => 'Hello from API!']);
});

Route::controller(ProductController::class)->prefix('products')->group(function () {
    Route::get('/','index');
    Route::post('/','store');
    Route::get('/{id}','show');
    Route::put('/{id}', 'update');
    Route::delete('/{id}', 'destroy');
});