<?php

namespace App\Http\Controllers\Auth;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Auth\Events\Registered;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Response;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\Rules;

class RegisteredUserController extends Controller
{
    /**
    * @OA\Post(
    *     path="/api/register",
    *     summary="Register a new user",
    *     tags={"Authentication"},
    *     @OA\RequestBody(
    *         required=true,
    *         @OA\JsonContent(
    *             required={"name","email","username","phoneNumber","pin","password","password_confirmation"},
    *             @OA\Property(property="name", type="string", example="John Doe"),
    *             @OA\Property(property="email", type="string", format="email", example="john.doe@example.com"),
    *             @OA\Property(property="username", type="string", example="johndoe"),
    *             @OA\Property(property="phoneNumber", type="string", example="+2348012345678"),
    *             @OA\Property(property="pin", type="string", format="password", example="1234"),
    *             @OA\Property(property="password", type="string", format="password", example="password123"),
    *         )
    *     ),
    *     @OA\Response(
    *         response=201,
    *         description="User registered successfully",
    *         @OA\JsonContent(@OA\Property(property="token", type="string"))
    *     ),
    *     @OA\Response(response=422, description="Validation error")
    * )
    *
    * Handle an incoming registration request.
    *
    * @throws \Illuminate\Validation\ValidationException
    */
    public function store(Request $request): Response|JsonResponse
    {
        $request->validate([
            'name' => ['required', 'string', 'max:255'],
            'email' => ['required', 'string', 'email', 'max:255', 'unique:users,email'],
            'username' => ['required', 'string', 'alpha_num', 'max:50', 'unique:users,username'],
            'phoneNumber' => ['required', 'string', 'max:20', 'unique:users,phoneNumber'],
            'pin' => ['required', 'digits:4'],
            'password' => ['required', 'confirmed', Rules\Password::defaults()],
        ]);
    
        $user = User::create([
            'name' => $request->name,
            'email' => $request->email,
            'username' => $request->input('username'),
            'phoneNumber' => $request->input('phoneNumber'),
            // password will be hashed by the model cast if present; pass raw to avoid double-hash
            'password' => $request->input('password'),
            // hash pin explicitly before saving
            'pin' => Hash::make($request->input('pin')),
        ]);
    
        event(new Registered($user));
    
        // If the request wants a JSON response, it's likely an API call.
        if ($request->wantsJson()) {
            $token = $user->createToken('api-token')->plainTextToken;
            return response()->json(['token' => $token], 201);
        }
    
        Auth::login($user); // For web-based requests
    
        return response()->noContent(); // For web-based requests
    }
}
