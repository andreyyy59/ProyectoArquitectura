<?php

namespace App\Http\Controllers;

abstract class Controller
{
    protected function success(mixed $data, int $code = 200)
    {
        return response()->json(['success' => true, 'data' => $data], $code);
    }

    protected function error(string $message, int $code = 400)
    {
        return response()->json(['success' => false, 'message' => $message], $code);
    }
}
