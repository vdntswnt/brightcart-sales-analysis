"""Load the CSVs into SQLite, run the SQL scripts, print results. Usage: python build_db.py"""
import sqlite3, pandas as pd
con = sqlite3.connect("shop.db")
for t in ["customers", "products", "orders", "order_items"]:
    pd.read_csv(f"data/{t}.csv").to_sql(t, con, if_exists="replace", index=False)
for name in ["01_model", "02_validate", "03_analysis"]:
    for stmt in (s for s in open(f"sql/{name}.sql").read().split(";") if any(k in s for k in ("SELECT", "CREATE", "DROP"))):
        cur = con.execute(stmt)
        if cur.description:
            print(name, [d[0] for d in cur.description])
            for r in cur.fetchall(): print("  ", r)
con.commit()
