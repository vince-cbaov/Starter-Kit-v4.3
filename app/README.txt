
Vince Falconer – Sites + Flask Portfolio (v2 with Apply Activities)
==================================================================

This archive contains:

1) index.html
   - Simple site with black background and colour-change button.

2) index_with_logo.html
   - Same as above, with a DevOps infinity logo (expects devops-logo.png alongside the HTML).

3) index_apply.html
   - Static page containing the full Apply & Prove activities (Modules 4, 5 & 6) formatted for the website.

4) flask-portfolio/
   - Flask project with:
     • app.py (routes for / and /apply)
     • templates/index.html (portfolio home)
     • templates/apply.html (Apply & Prove activities)
     • static/styles.css
     • static/devops-logo.png

Run the Flask site
------------------
cd flask-portfolio
pip install flask
python app.py

Then open http://127.0.0.1:5000 and click **Apply Activities** in the nav.
