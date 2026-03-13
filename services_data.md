# Service Data — Test Environment (10.8.0.11)

## Port Mapping Convention

All services run on **10.8.0.11** with the following port pattern:
- `81XX` — HTTP service port (container :8080)
- `94XX` — gRPC port (container :8993)
- `154XX` — PostgreSQL (container :5432)
- `63XX` — Redis (container :6379)
- `82XX` — Vault (container :8200)
- `93XX` — Kafdrop (container :9000)

External gRPC endpoint: `grpc://apitesla.test.gsmsoft.eu/` (TLS)

---

## Core Services

| Service | HTTP | gRPC | PG | Redis | Other | Prod URL |
|---------|------|------|-----|-------|-------|----------|
| api-gateway | 8101 | 9401 | — | — | — | https://apiadmin.test.gsmsoft.eu/api-gateway |
| users | 8102 | 9402 | 15402 | 6382 | vault:8202, kafdrop:9302 | https://apiadmin.test.gsmsoft.eu/users |
| accounts | 8103 | 9403 | 15403 | 6383 | vault:8203, kafdrop:9303 | https://apiadmin.test.gsmsoft.eu/accounts |
| orders | 8104 | 9404 | 15404 | 6384 | — | https://apiadmin.test.gsmsoft.eu/orders |
| matcher | 8105 | 9405 | — | 6385 | — | https://apiadmin.test.gsmsoft.eu/matcher |
| orderbook | 8106 | 9406 | — | 6386 | — | https://apiadmin.test.gsmsoft.eu/orderbook |
| market-maker | 8107 | 9407 | 15407 | — | — | https://apiadmin.test.gsmsoft.eu/market-maker |
| admin-api | 8108 | — | 15405 | — | — | https://apiadmin.test.gsmsoft.eu |
| scoring | 8108 | 9408 | 15408 | — | — | https://apiadmin.test.gsmsoft.eu/scoring |
| crypto-gateway | 8109 | 9409 | 15409 | 6389 | — | https://apiadmin.test.gsmsoft.eu/crypto-gateway |
| notifications | 8111 | 9411 | 15411 | 6391 | — | https://apiadmin.test.gsmsoft.eu/notifications |
| cards | 8112 | 9412 | 15412 | — | — | https://apiadmin.test.gsmsoft.eu/cards |
| kyc | 8126 | 9426 | 15426 | — | — | https://apiadmin.test.gsmsoft.eu/kyc |
| limiter | 8127 | 9427 | 15427 | 6327 | — | https://apiadmin.test.gsmsoft.eu/limiter |
| courses | 8128 | 9428 (user) / 10428 (admin) | 15428 | 6328 | — | https://apiadmin.test.gsmsoft.eu/courses |
| sender | 8129 | 9429 | 15429 | 6329 | — | https://apiadmin.test.gsmsoft.eu/sender |
| quick-exchange | 8130 | 9430 | 15430 | 6330 | — | https://apiadmin.test.gsmsoft.eu/quick-exchange |

## Crypto Adapters

| Adapter | HTTP | gRPC | Prod URL |
|---------|------|------|----------|
| eth-adapter | 8110 | 9410 | https://apiadmin.test.gsmsoft.eu/eth-adapter |
| btc-adapter | 8114 | 9414 | https://apiadmin.test.gsmsoft.eu/btc-adapter |
| tron-adapter | 8115 | 9415 | https://apiadmin.test.gsmsoft.eu/tron-adapter |
| dot-adapter | 8116 | 9416 | https://apiadmin.test.gsmsoft.eu/dot-adapter |
| ton-adapter | 8117 | 9417 | https://apiadmin.test.gsmsoft.eu/ton-adapter |
| sol-adapter | 8118 | 9418 | https://apiadmin.test.gsmsoft.eu/sol-adapter |
| bch-adapter | 8119 | 9419 | https://apiadmin.test.gsmsoft.eu/bch-adapter |
| ltc-adapter | 8120 | 9420 | https://apiadmin.test.gsmsoft.eu/ltc-adapter |
| doge-adapter | 8121 | 9421 | https://apiadmin.test.gsmsoft.eu/doge-adapter |
| tal-adapter | 8122 | 9422 | https://apiadmin.test.gsmsoft.eu/tal-adapter |
| xrp-adapter | 8123 | 9423 | https://apiadmin.test.gsmsoft.eu/xrp-adapter |
| ada-adapter | 8124 | 9424 | https://apiadmin.test.gsmsoft.eu/ada-adapter |
| bnb-adapter | 8125 | 9425 | https://apiadmin.test.gsmsoft.eu/bnb-adapter |

## Acquiring & Exchange Engines

| Service | HTTP | gRPC | PG | Redis | Prod URL |
|---------|------|------|-----|-------|----------|
| fenige-adapter | 8131 | 9431 | 15431 | 6331 | https://apiadmin.test.gsmsoft.eu/fenige-adapter |
| crypto-acquiring | 8133 | 9433 | 15433 | — | https://apiadmin.test.gsmsoft.eu/crypto-acquiring |
| crypto-acquiring-sender | 8134 | 9434 | 15434 | — | https://apiadmin.test.gsmsoft.eu/crypto-acquiring-sender |
| finder-engine | 8135 | 9435 | 15435 | — | https://apiadmin.test.gsmsoft.eu/finder-engine |
| mini-crypto-acquiring | 8136 | 9436 | 15436 | — | https://apiadmin.test.gsmsoft.eu/mini-crypto-acquiring |
| acquiring-processing | — | 9437 / 10437 (admin) | 15437 | — | https://apiadmin.test.gsmsoft.eu/acquiring-processing |
| exchanger | 8138 | 9438 | 15438 | — | https://apiadmin.test.gsmsoft.eu/exchanger |

> **Note:** acquiring-processing uses IP 10.8.0.1 (not 10.8.0.11)

---

## Admin-API gRPC Dependencies

These are the services admin-api connects to directly via gRPC. Update `.env` accordingly:

```env
USER_SERVICE_GRPC_ADDR=10.8.0.11:9402
ACCOUNT_SERVICE_GRPC_ADDR=10.8.0.11:9403
SCORING_SERVICE_GRPC_ADDR=10.8.0.11:9408
LIMITER_SERVICE_GRPC_ADDR=10.8.0.11:9427
NOTIFY_SERVICE_GRPC_ADDR=10.8.0.11:9411
COURSES_SERVICE_GRPC_ADDR=10.8.0.11:10428
```

---

## Database Credentials (TEST)

| Service | Host | DB | User | Password |
|---------|------|-----|------|----------|
| accounts | 10.8.0.11:15403 | accounts_test | accounts_test | esfP8xuX8Fw6G0WB |
| orders | 10.8.0.11:15404 | orders_test | orders_test | mhqVHV9R0HlrDp3Y |
| users | 10.8.0.11:15402 | users_test | users_test | kvPfwLp3MkAbqWrK |
| market_maker | 10.8.0.11:15407 | market_maker_test | market_maker_test | eJUgRfuxDcQHrgUb |
| scoring | 10.8.0.11:15408 | scoring_test | scoring_test | RRMCezFGFtCyfwSo |
| crypto-gateway | 10.8.0.11:15409 | crypto_gw_test | crypto_gw_test | WhQtqETa5vHHddMK |
| cards | 10.8.0.11:15412 | cards_db_test | cards_users_test | oigghqu542ChGP5O |
| kyc | 10.8.0.11:15426 | kyc_test_db | kyc_test_user | sQ5hggao1odxJWyp |
| admin-api | 10.8.0.11:15405 | admin_api_test | admin_api | lt6eTQiB6EhWOqwe |
| limiter | 10.8.0.11:15427 | limiter_db_test | limiter_user_test | qweT42_sde |
| sender | 10.8.0.1:15429 | sender_test_db | sender_test | Sender_passwd_test |

---

## Git Repositories

| Service | Repository |
|---------|-----------|
| api-gateway | https://gitlab.com/gsmsoft1/exchange/api-gateway.git |
| users | https://gitlab.com/gsmsoft1/exchange/users.git |
| accounts | https://gitlab.com/gsmsoft1/exchange/accounts.git |
| orders | https://gitlab.com/gsmsoft1/exchange/orders.git |
| orderbook | https://gitlab.com/gsmsoft1/exchange/orderbook.git |
| matcher | https://gitlab.com/gsmsoft1/exchange/matcher.git |
| market-maker | https://gitlab.com/gsmsoft1/exchange/market-maker.git |
| admin-api | https://gitlab.com/gsmsoft1/exchange/admin-api.git |
| scoring | https://gitlab.com/gsmsoft1/exchange/scoring.git |
| crypto-gateway | https://gitlab.com/gsmsoft1/exchange/crypto-gateway.git |
| notifications | https://gitlab.com/gsmsoft1/exchange/notifications.git |
| cards | https://gitlab.com/gsmsoft1/exchange/cards.git |
| kyc | https://gitlab.com/gsmsoft1/exchange/kyc.git |
| limiter | https://gitlab.com/gsmsoft1/exchange/limiter.git |
| courses | https://gitlab.com/gsmsoft1/exchange/courses.git |
| sender | https://gitlab.com/gsmsoft1/exchange/sender.git |
| quick-exchange | https://gitlab.com/gsmsoft1/exchange/quick-exchange.git |
| treasury | https://gitlab.com/gsmsoft1/exchange/treasury.git |
| market-data | https://gitlab.com/gsmsoft1/exchange/market-data.git |
| liquidity-providers | https://gitlab.com/gsmsoft1/exchange/liquidity-providers.git |
| acquiring/gateway | https://gitlab.com/gsmsoft1/exchange/acquiring/gateway.git |
| acquiring/processing | https://gitlab.com/gsmsoft1/exchange/acquiring/processing.git |
| acquiring/fenige_adapter | https://gitlab.com/gsmsoft1/exchange/acquiring/fenige_adapter.git |
| acquiring-processing | https://gitlab.com/gsmsoft1/exchange/acquiring-processing.git |
| acquiring-sender | https://gitlab.com/gsmsoft1/exchange/acquiring-sender.git |
| fuse-pay-service | https://gitlab.com/gsmsoft1/exchange/fuse-pay-service.git |
| crypto-acquiring | https://gitlab.com/gsmsoft1/exchange/crypto-acquiring.git |
| mini-crypto-acquiring | https://gitlab.com/gsmsoft1/exchange/mini-crypto-acquiring.git |
| common | https://gitlab.com/gsmsoft1/exchange/common.git |
| grafana-dashboards | https://gitlab.com/gsmsoft1/exchange/grafana-dashboards.git |
| exchanger_processor | https://gitlab.com/gsmsoft1/exchange/exchange_engines/exchanger_processor.git |
| exchanger_gateway | https://gitlab.com/gsmsoft1/exchange/exchange_engines/exchanger_gateway.git |
| exchanger_router | https://gitlab.com/gsmsoft1/exchange/exchange_engines/exchanger_router.git |
| taler_adapter | https://gitlab.com/gsmsoft1/exchange/exchange_engines/taler_adapter.git |
| chengelly_adapter | https://gitlab.com/gsmsoft1/exchange/exchange_engines/chengelly_adapter.git |
| searcher/engine | https://gitlab.com/gsmsoft1/exchange/searcher/engine.git |
| searcher/sphinx | https://gitlab.com/gsmsoft1/exchange/searcher/sphinx.git |
| searcher/adapter-core | https://gitlab.com/gsmsoft1/exchange/searcher/adapter-core.git |
| admin_panel | https://gitlab.com/gsmsoft1/exchange_front/admin_panel.git |
