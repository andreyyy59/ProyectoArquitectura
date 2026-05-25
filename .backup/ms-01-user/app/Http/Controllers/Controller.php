<?php

namespace App\Http\Controllers;

abstract class Controller
{
    protected function success(mixed $data, int $code = 200)
    {
        return response()->json(['success' => true, 'data' => $data], $code);
    }

    protected function error(string $message, int $code = 400, array $errors = [])
    {
        $response = ['success' => false, 'message' => $message];
        if (!empty($errors)) {
            $response['errors'] = $errors;
        }
        return response()->json($response, $code);
    }
}
