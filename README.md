# ExBanking

My code for test task with Balanced.io

## Run test

```
> mix deps.get
> mix test
```

## Architecture

1. Each user is dynamically created and supervised by UsersSupervisor.
2. Each user is in a seperated genserver process, therefore request for user A will not affect performance of requests for user B.
3. A Pool server will keep track of connection value for each user.
4. Use elixir native libraries only without any external ones (only for test and code quality).
5. Not use any database / disc storage.

## To do

Things are not in requirements but would be better in real use case:

1. Transaction history might be stored for report/audit purpose.
2. Better use [Registry](https://hexdocs.pm/elixir/Registry.html) to name user process, instead of atom.
3. Handle user process in case of failure if any.