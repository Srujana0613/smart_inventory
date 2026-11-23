# Smart Inventory Management with Predictive Sales Analytics

A Python + MySQL application for supermarkets and small retail shops: inventory,
expiry (FEFO) tracking, billing, supplier management, demand forecasting and a
Streamlit dashboard.

## Setup
1. Install Python 3.12+, MySQL Server + Workbench, Git.
2. Create a virtual environment and install dependencies:
   `pip install -r requirements.txt`
3. Run `database/00_create_database.sql` in MySQL Workbench.
4. Copy `.env.example` to `.env` and put in your MySQL password.
5. Verify: `python test_setup.py`
6. Build tables + sample data: `python -m modules.setup_database`
7. Run schema tests: `python -m unittest tests.test_schema -v`

Phase 3 demo: `python demo_phase3.py` | tests: `python -m unittest discover -s tests -t . -v`

Design notes and ER diagram: `docs/database_design.md`

## Progress
- [x] Phase 1 – Environment setup
- [x] Phase 2 – Database design
- [x] Phase 3 – Python–MySQL connection
- [ ] Phase 4 – Product & inventory management
- [ ] Phase 5 – Expiry management
- [ ] Phase 6 – Sales & billing
- [ ] Phase 7 – Purchases & suppliers
- [ ] Phase 8 – Predictive analytics
- [ ] Phase 9 – Dashboard
- [ ] Phase 10 – Testing & GitHub
