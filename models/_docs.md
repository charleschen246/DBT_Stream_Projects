{% docs title_key %}
Surrogate key for a title on a platform: a hash of `platform_id` + `show_id`.
The source `show_id` (s1, s2, ...) restarts on every platform, so it can't be the key on its own.
{% enddocs %}

{% docs platform_id %}
Streaming platform identifier: `amazon_prime`, `disney_plus`, `hulu` or `netflix`.
Foreign key to `dim_platforms`.
{% enddocs %}

{% docs content_type %}
`movie` or `tv_show`. Normalized from the source values 'Movie' and 'TV Show'.
{% enddocs %}

{% docs release_year %}
Year the title was originally released, which is not the year it reached the platform.
{% enddocs %}

{% docs date_added %}
Date the title was added to the platform. NULL when the source doesn't provide it,
which is the case for most Amazon Prime titles.
{% enddocs %}

{% docs rating_id %}
Standardized maturity rating. Raw codes are mapped through the `rating_mappings` seed,
so aliases like `UR`, `UNRATED` and `NOT_RATE` all become `NR`. `UNKNOWN` means the rating
was missing or unmapped. Foreign key to `dim_ratings`.
{% enddocs %}

{% docs duration_minutes %}
Runtime in minutes. Populated for movies only.
{% enddocs %}

{% docs season_count %}
Number of seasons. Populated for TV shows only.
{% enddocs %}
