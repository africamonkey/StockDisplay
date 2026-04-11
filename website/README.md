# StockDisplay Website

This folder contains the official website for StockDisplay app.

## Deploy to GitHub Pages

### Option 1: Use website folder as source

1. Go to repository **Settings** → **Pages**
2. Under "Build and deployment", select:
   - **Source**: Deploy from a branch
   - **Branch**: main `/ (root)`
3. Change the folder path to `/website` instead of `/ (root)`
4. Click **Save**

### Option 2: Push to gh-pages branch

```bash
git checkout -b gh-pages
git push origin gh-pages
```

Then go to repository **Settings** → **Pages** and select the `gh-pages` branch.

## Files

- `index.html` - Main website page
- `privacy.html` - Privacy policy page
- `dashboard1.png` - App screenshot (Dashboard)
- `dashboard2.png` - App screenshot (Dark Mode)
- `settings.png` - App screenshot (Settings)

## Local Preview

Simply open `index.html` in a browser, or use a local server:

```bash
python3 -m http.server 8000
```

Then visit `http://localhost:8000`
