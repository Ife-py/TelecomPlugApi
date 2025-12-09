<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\LoginController;
use App\Http\Controllers\Api\UserController;
use App\Http\Controllers\Api\Admin\AdminAuthController;
use App\Http\Controllers\Auth\RegisteredUserController;
use App\Http\Controllers\Api\ProductController;
use app\Http\Controllers\TestController;

Route::get('/test', [App\Http\Controllers\TestController::class, 'index']);

Route::controller(RegisteredUserController::class)->prefix('register')->name('register.')->group(function () {
    Route::post('/', 'store');
});

Route::controller(LoginController::class)->prefix('login')->name('login.')->group(function () {
    Route::post('/', 'store');
});

Route::middleware(['auth:token-cookie'])->group(function () {
    Route::get('/user', function (Request $request) {
        return $request->user();
    });
    Route::controller(UserController::class)->prefix('user')->name('user.')->group(function () {
        Route::get('/', 'show');
        Route::put('/', 'update');
    });
    Route::post('/logout', [LoginController::class, 'destroy']);
});

Route::prefix('admin')->name('admin.')->group(function () {
    Route::controller(AdminAuthController::class)->prefix('login')->name('login.')->group(function () {
        Route::post('/', 'login');
    });

    Route::middleware(['auth:sanctum'])->group(function () {
        Route::post('/logout', [AdminAuthController::class, 'logout']);
    });
});

// Route::get('/hello', function () {
//     return response()->json(['message' => 'Hello from API!']);
// });

// Route::controller(ProductController::class)->prefix('products')->group(function () {
//     Route::get('/','index');
//     Route::post('/','store');
//     Route::get('/{id}','show');
//     Route::put('/{id}', 'update');
//     Route::delete('/{id}', 'destroy');
// });