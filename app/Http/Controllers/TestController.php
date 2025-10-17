<?php

namespace App\Http\Controllers;

class TestController extends Controller
{
    /**
     * @OA\Get(
     *     path="/api/test",
     *     summary="Test endpoint to verify Swagger setup",
     *     tags={"Test"},
     *
     *     @OA\Response(
     *         response=200,
     *         description="Swagger is working!"
     *     )
     * )
     */
    public function index()
    {
        return response()->json(['message' => 'Swagger is working!']);
    }
}
