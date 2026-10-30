"""Generate a SIMULATED e-commerce dataset (seeded, reproducible). Not real company data.
Usage: python generate_data.py  -> writes data/customers.csv, products.csv, orders.csv, order_items.csv"""
import numpy as np, pandas as pd
rng = np.random.default_rng(42)

regions = ["North", "South", "East", "West"]
channels = ["Organic", "Paid Search", "Social", "Email", "Referral"]
cats = {  # category: (n_products, price_low, price_high, cost_ratio)
    "Electronics": (8, 40, 600, 0.78), "Home & Kitchen": (10, 15, 180, 0.62),
    "Fashion": (10, 12, 120, 0.50), "Beauty": (6, 8, 70, 0.42), "Sports": (6, 15, 220, 0.60)}
prod = []
pid = 1
for c, (n, lo, hi, cr) in cats.items():
    for _ in range(n):
        price = round(float(np.exp(rng.uniform(np.log(lo), np.log(hi)))), 2)
        prod.append((pid, f"{c[:4].upper()}-{pid:03d}", c, price, round(price * (cr + rng.uniform(-.05, .05)), 2)))
        pid += 1
products = pd.DataFrame(prod, columns=["product_id", "product_name", "category", "unit_price", "unit_cost"])

N = 4000
signup = pd.to_datetime("2024-01-01") + pd.to_timedelta(rng.integers(0, 700, N), unit="D")
customers = pd.DataFrame({
    "customer_id": np.arange(1, N + 1),
    "signup_date": signup.date,
    "region": rng.choice(regions, N, p=[.22, .26, .24, .28]),
    "channel": rng.choice(channels, N, p=[.30, .25, .20, .15, .10])})

season = {1: .8, 2: .8, 3: .9, 4: .95, 5: 1.0, 6: .95, 7: .9, 8: .95, 9: 1.0, 10: 1.15, 11: 1.6, 12: 1.7}
end = pd.Timestamp("2025-12-31")
orders, items = [], []
oid = 1
loyal = rng.random(N) < 0.35          # 35% of customers buy frequently
for i, row in customers.iterrows():
    start = pd.Timestamp(row.signup_date)
    span = (end - start).days
    # first order within 10 days of signup, then repeat orders with exponential gaps
    t = float(rng.integers(0, 11)); days = [t]
    mean_gap = 45 if loyal[i] else 220
    while True:
        t += rng.exponential(mean_gap)
        if t > span or len(days) >= 25: break
        days.append(t)
    for d in days:
        dt = start + pd.Timedelta(days=int(d))
        if d > 10 and rng.random() > season[dt.month] / 1.7 + 0.35:   # seasonality thinning of repeat orders
            continue
        k = int(rng.choice([1, 2, 3, 4], p=[.5, .3, .15, .05]))
        disc_order = rng.choice([0, .05, .10, .20, .30], p=[.45, .15, .2, .13, .07])
        if dt.month in (11, 12): disc_order = rng.choice([0, .10, .20, .30], p=[.2, .2, .3, .3])
        orders.append((oid, int(row.customer_id), dt.date(), float(disc_order), rng.choice(["Card", "UPI", "COD", "Wallet"], p=[.4, .35, .15, .1])))
        for p in products.sample(k, random_state=int(rng.integers(1e9))).itertuples():
            qty = int(rng.choice([1, 2, 3], p=[.75, .18, .07]))
            items.append((oid, int(p.product_id), qty))
        oid += 1
orders = pd.DataFrame(orders, columns=["order_id", "customer_id", "order_date", "discount_pct", "payment_method"])
items = pd.DataFrame(items, columns=["order_id", "product_id", "quantity"])
customers.to_csv("data/customers.csv", index=False); products.to_csv("data/products.csv", index=False)
orders.to_csv("data/orders.csv", index=False); items.to_csv("data/order_items.csv", index=False)
print(len(customers), "customers", len(products), "products", len(orders), "orders", len(items), "items")
