<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Http\JsonResponse;

class AdminAuthController extends Controller
{
    /**
     * @OA\Post(
     *     path="/api/admin/login",
     *     summary="Admin Login",
     *     tags={"Admin"},
     *     @OA\RequestBody(
     *         required=true,
     *         @OA\JsonContent(
     *             required={"username", "password"},
     *             @OA\Property(property="username", type="string", example="admin"),
     *             @OA\Property(property="password", type="string", example="secret123")
     *         )
     *     ),
     *     @OA\Response(
     *         response=200,
     *         description="Admin logged in successfully",
     *         @OA\JsonContent(
     *             @OA\Property(property="message", type="string", example="Login successful"),
     *             @OA\Property(property="token", type="string", example="1|abcd1234...")
     *         )
     *     ),
     *     @OA\Response(response=401, description="Invalid credentials")
     * )
     */
    public function login(Request $request): JsonResponse
    {
        // Hardcoded admin credentials
        $adminUsername = 'admin';
        $adminPassword = 'test1234'; 

        $request->validate([
            'username' => 'required|string',
            'password' => 'required|string'
        ]);

        if (
            $request->username !== $adminUsername ||
            $request->password !== $adminPassword
        ) {
            return response()->json([
                'message' => 'Invalid admin credentials'
            ], 401);
        }

        // Create token for admin (no database user)
        $fakeAdminUser = (object) ['id' => 9999, 'name' => 'System Admin'];

        $token = auth('sanctum')
            ->createToken('admin-token')
            ->plainTextToken;

        return response()->json([
            'message' => 'Login successful',
            'token' => $token,
        ]);
    }

    /**
     * @OA\Post(
     *     path="/api/admin/logout",
     *     summary="Admin Logout",
     *     tags={"Admin"},
     *     security={{"sanctum": {}}},
     *     @OA\Response(
     *         response=200,
     *         description="Logged out successfully",
     *         @OA\JsonContent(@OA\Property(property="message", type="string"))
     *     )
     * )
     */
    public function logout(Request $request): JsonResponse
    {
        // Delete only the current token
        $request->user()->currentAccessToken()->delete();

        return response()->json([
            'message' => 'Logged out successfully'
        ]);
    }
}
