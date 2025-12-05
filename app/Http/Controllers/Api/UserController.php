<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\Rules;
use Illuminate\Http\JsonResponse;

class UserController extends Controller
{
    /**
     * @OA\Get(
     *     path="/api/user",
     *     summary="Get authenticated user profile",
     *     tags={"User"},
     *     security={{"sanctum": {}}},
     *     @OA\Response(
     *         response=200,
     *         description="Authenticated user profile",
     *         @OA\JsonContent(
     *             type="object",
     *             @OA\Property(property="id", type="integer"),
     *             @OA\Property(property="name", type="string"),
     *             @OA\Property(property="email", type="string"),
     *             @OA\Property(property="username", type="string"),
     *             @OA\Property(property="phoneNumber", type="string"),
     *             @OA\Property(property="created_at", type="string"),
     *             @OA\Property(property="updated_at", type="string")
     *         )
     *     ),
     *     @OA\Response(response=401, description="Unauthenticated")
     * )
     */
    public function show(Request $request): JsonResponse
    {
        return response()->json($request->user());
    }

    /**
     * @OA\Put(
     *     path="/api/user",
     *     summary="Update authenticated user's profile",
     *     tags={"User"},
     *     security={{"sanctum": {}}},
     *     @OA\RequestBody(
     *         required=true,
     *         @OA\JsonContent(
     *             @OA\Property(property="name", type="string", example="John Doe"),
     *             @OA\Property(property="email", type="string", example="john@example.com"),
     *             @OA\Property(property="username", type="string", example="john123"),
     *             @OA\Property(property="pin", type="string", example="1234")
     *         )
     *     ),
     *     @OA\Response(
     *         response=200,
     *         description="Profile updated successfully",
     *         @OA\JsonContent(
     *             @OA\Property(property="message", type="string"),
     *             @OA\Property(property="user", type="object")
     *         )
     *     ),
     *     @OA\Response(response=422, description="Validation error")
     * )
     */
    public function updateContact(Request $request): JsonResponse
    {
        $user = $request->user();

        $validated = $request->validate([
            'name' => ['sometimes', 'string', 'max:255'],
            'email' => ['sometimes', 'email', 'unique:users,email,' . $user->id],
            'username' => ['sometimes', 'string', 'alpha_num', 'max:50', 'unique:users,username,' . $user->id],
            'pin' => ['sometimes', 'digits:4'],
        ]);

        $user->update($validated);

        return response()->json([
            'message' => 'Profile updated successfully',
            'user' => $user,
        ]);
    }

    /**
     * @OA\Put(
     *     path="/api/user/pin",
     *     summary="Update user's transaction PIN",
     *     tags={"User"},
     *     security={{"sanctum": {}}},
     *     @OA\RequestBody(
     *         required=true,
     *         @OA\JsonContent(
     *             required={"pin"},
     *             @OA\Property(property="pin", type="string", example="1234")
     *         )
     *     ),
     *     @OA\Response(
     *         response=200,
     *         description="PIN updated successfully",
     *         @OA\JsonContent(
     *             @OA\Property(property="message", type="string"),
     *             @OA\Property(property="user", type="object")
     *         )
     *     ),
     *     @OA\Response(response=422, description="Validation error")
     * )
     */
    public function updatePin(Request $request): JsonResponse
    {
        $user = $request->user();

        $validated = $request->validate([
            'pin' => ['required', 'digits:4'],
        ]);

        $user->pin = Hash::make($validated['pin']);
        $user->save();

        return response()->json([
            'message' => 'PIN updated successfully',
            'user' => $user,
        ]);
    }

    /**
     * @OA\Put(
     *     path="/api/user/password",
     *     summary="Update authenticated user's password",
     *     tags={"User"},
     *     security={{"sanctum": {}}},
     *     @OA\RequestBody(
     *         required=true,
     *         @OA\JsonContent(
     *             required={"password", "password_confirmation"},
     *             @OA\Property(property="password", type="string", example="NewPassword123!"),
     *             @OA\Property(property="password_confirmation", type="string", example="NewPassword123!")
     *         )
     *     ),
     *     @OA\Response(
     *         response=200,
     *         description="Password updated successfully",
     *         @OA\JsonContent(
     *             @OA\Property(property="message", type="string"),
     *             @OA\Property(property="user", type="object")
     *         )
     *     ),
     *     @OA\Response(response=422, description="Validation error")
     * )
     */
    public function updatePassword(Request $request): JsonResponse
    {
        $user = $request->user();

        $validated = $request->validate([
            'password' => ['required', 'confirmed', Rules\Password::defaults()],
        ]);

        $user->password = Hash::make($validated['password']);
        $user->save();

        return response()->json([
            'message' => 'Password updated successfully',
            'user' => $user,
        ]);
    }

    /**
     * @OA\Get(
     *     path="/api/users",
     *     summary="Get all users (Admin only)",
     *     tags={"User"},
     *     security={{"sanctum": {}}},
     *     @OA\Response(
     *         response=200,
     *         description="List of users",
     *         @OA\JsonContent(
     *             type="array",
     *             @OA\Items(type="object")
     *         )
     *     )
     * )
     */
    public function index(): JsonResponse
    {
        return response()->json(User::all());
    }
}
