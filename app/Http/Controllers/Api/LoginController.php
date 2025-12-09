<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\Auth\LoginRequest;
use Illuminate\Http\Request;
use Illuminate\Http\Response;

class LoginController extends Controller
{
    /**
     * @OA\Post(
     *     path="/api/login",
     *     summary="Authenticate user and get token",
     *     tags={"Authentication"},
     *     @OA\RequestBody(
     *         required=true,
     *         @OA\JsonContent(
     *             required={"email","password"},
     *             @OA\Property(property="email", type="string", format="email", example="john.doe@example.com"),
     *             @OA\Property(property="password", type="string", format="password", example="password123")
     *         )
     *     ),
     *     @OA\Response(
     *         response=200,
     *         description="Authentication successful",
     *         @OA\JsonContent(
     *             @OA\Property(property="user", type="object"),
     *             @OA\Property(property="token", type="string")
     *         )
     *     ),
     *     @OA\Response(response=422, description="Validation error or invalid credentials")
     * )
     */
    public function store(LoginRequest $request): \Illuminate\Http\JsonResponse
        {
            // Validate and authenticate
            $request->authenticate();
            $user = $request->user();

            // Create token
            $token = $user->createToken('api-token')->plainTextToken;

            // Return JSON with cookie
            return response()
                ->json([
                    'message' => 'Login successful',
                    'user' => $user,
                    'token' => $token, // optional if you're using cookie only
                ],200)
                ->cookie(
                    'auth_token',     // name
                    $token,           // value
                    60 * 24,          // expiration (minutes) = 1 day
                    '/',              // path
                    null,             // domain (null = backend domain)
                    true,             // secure (MUST be true on HTTPS)
                    true,             // httpOnly (true = safer)
                    false,            // raw
                    'Lax'             // SameSite: Lax | Strict | None
                );
        }


    /**
     * @OA\Post(
     *     path="/api/logout",
     *     summary="Log out the current user",
     *     tags={"Authentication"},
     *     security={{"sanctum": {}}},
     *     @OA\Response(
     *         response=204,
     *         description="Successfully logged out"
     *     ),
     *     @OA\Response(response=401, description="Unauthenticated")
     * )
     */
    public function destroy(Request $request): Response 
    {
        // Revoke the token that was used to authenticate the current request... 
        $request->user()->currentAccessToken()->delete();
        return response()->noContent();
    }

}
