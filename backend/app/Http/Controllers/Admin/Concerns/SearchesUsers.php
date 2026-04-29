<?php

namespace App\Http\Controllers\Admin\Concerns;

use Illuminate\Database\Eloquent\Builder;

/**
 * Trait SearchesUsers
 *
 * Factorise la recherche utilisateur par nom/prénom/email,
 * pattern dupliqué dans 6+ contrôleurs admin.
 *
 * Usage:
 *   $this->applyUserSearch($query, $search);                     // direct User query
 *   $this->applyRelatedUserSearch($query, 'patient', $search);   // via relation
 */
trait SearchesUsers
{
    /**
     * Apply name/email search directly on a User query.
     */
    protected function applyUserSearch(Builder $query, string $search): Builder
    {
        return $query->where(function (Builder $q) use ($search) {
            $q->where('first_name', 'LIKE', "%{$search}%")
                ->orWhere('last_name', 'LIKE', "%{$search}%")
                ->orWhere('email', 'LIKE', "%{$search}%");
        });
    }

    /**
     * Apply name/email search via a relationship (e.g. 'user', 'patient', 'sender').
     */
    protected function applyRelatedUserSearch(Builder $query, string $relation, string $search): Builder
    {
        return $query->whereHas($relation, function (Builder $q) use ($search) {
            $q->where('first_name', 'LIKE', "%{$search}%")
                ->orWhere('last_name', 'LIKE', "%{$search}%")
                ->orWhere('email', 'LIKE', "%{$search}%");
        });
    }
}
