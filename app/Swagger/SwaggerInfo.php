<?php

/**
 * @OA\Info(
 *     title="Telecom API Documentation",
 *     version="1.0.0",
 *     description="API documentation for the Telecom application.",
 *     @OA\Contact(
 *         email="support@smarthousingportal.com",
 *         name="Smart Housing Dev Team"
 *     ),
 *     @OA\License(
 *         name="MIT",
 *         url="https://opensource.org/licenses/MIT"
 *     )
 * )
 *
 * @OA\Server(
 *     url="http://127.0.0.1:8000",
 *     description="Local Development Server"
 * )
 *
 * @OA\Server(
 *     url="https://your-production-domain.com",
 *     description="Production Server"
 * )
 *
 * @OA\SecurityScheme(
 *     securityScheme="sanctum",
 *     type="http",
 *     scheme="bearer",
 *     bearerFormat="JWT",
 *     description="Enter token in format (Bearer <token>)"
 * )
 */
