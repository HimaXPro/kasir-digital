<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class StockMutation extends Model
{
    use HasFactory;

    protected $guarded = ['id'];

    /**
     * Relasi ke model Product
     */
    public function product(): BelongsTo
    {
        return $this->belongsTo(Product::class);
    }
}
