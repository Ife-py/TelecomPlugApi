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

Route::get('/debug-auth', function (Request $request) {
    return [
        'user' => $request->user(),
        'headers' => request()->header(),
        'token' => request()->bearerToken(),
    ];
});


// Debug route for l5-swagger assets - only enabled when APP_DEBUG=true
Route::get('/_debug/l5-swagger', function () {
    if (!config('app.debug')) {
        abort(404);
    }

    $doc = 'default';
    $cfgPath = config('l5-swagger.documentations.'.$doc.'.paths.swagger_ui_assets_path');
    $baseResolved = base_path($cfgPath ?: '');
    $realPath = realpath($baseResolved) ?: '';
    $asset = $realPath ? $realPath.DIRECTORY_SEPARATOR.'swagger-ui.css' : '';

    return response()->json([
        'app_debug' => config('app.debug'),
        'documentation' => $doc,
        'config_value' => $cfgPath,
        'base_resolved' => $baseResolved,
        'realpath' => $realPath,
        'asset_file' => $asset,
        'asset_exists' => $asset ? file_exists($asset) : false,
        'public_vendor_listing' => is_dir(base_path('public/vendor/l5-swagger'))
            ? array_map(fn($p) => basename($p), \Illuminate\Support\Facades\File::files(base_path('public/vendor/l5-swagger')))
            : [],
    ]);
});

require __DIR__.'/auth.php';
