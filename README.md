# 回数 - Kaisuu

Kaisuu streams live data from Twitter to gather kanji frequency usage patterns in tweets. It can be used to optimize the order of your kanji studies or to make assumptions about what people in Japan are tweeting about.

## Installation

Install dependencies with

```
mix deps.get
```

Install Node.js dependencies with

```
npm install
```

Create a `./config/dev.secret.exs` with your twitter credentials

```Elixir
use Mix.Config

config :extwitter, :oauth, [
   consumer_key:        "CONSUMER_KEY",
   consumer_secret:     "CONSUMER_SECRET",
   access_token:        "ACCESS_TOKEN",
   access_token_secret: "ACCESS_TOKEN_SECRET"
]
```

Start Phoenix endpoint with

```
mix phoenix.server
```

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.
