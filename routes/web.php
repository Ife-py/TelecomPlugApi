<?php

use Illuminate\Support\Facades\Route;
use Illuminate\Support\Facades\File;

Route::get('/api-docs.json', function () {
    $path = storage_path('api-docs/api-docs.json');
    if (!File::exists($path)) {
        abort(404, 'Swagger JSON not found');
    }
    return response()->file($path, [
        'Content-Type' => 'application/json',
    ]);
});


Route::get('/', function () {
    return redirect('/api/documentation');
});

require __DIR__.'/auth.php';
