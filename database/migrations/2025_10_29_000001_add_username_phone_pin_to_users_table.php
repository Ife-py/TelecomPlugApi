<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        Schema::table('users', function (Blueprint $table) {
            // Add username and phone as unique columns and a hashed pin
            // make nullable initially to avoid migration failures on existing data
            $table->string('username', 50)->nullable()->unique()->after('email');
            $table->string('phoneNumber', 20)->nullable()->unique()->after('username');
            // store hashed pin (nullable for backward compatibility)
            $table->string('pin', 255)->nullable()->after('phoneNumber');
        });
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropColumn(['pin']);
            $table->dropUnique(['phoneNumber']);
            $table->dropColumn(['phoneNumber']);
            $table->dropUnique(['username']);
            $table->dropColumn(['username']);
        });
    }
};
