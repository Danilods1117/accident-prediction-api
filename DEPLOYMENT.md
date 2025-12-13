# Deployment Guide - Accident Prediction API

This guide will help you deploy your Flask API backend to the cloud so your Flutter app can work independently.

## Prerequisites
- Git installed on your computer
- A GitHub account (free)
- Your model files (.pkl, .json) in the project directory

---

## Option 1: Deploy to Render (RECOMMENDED - Free & Easy)

Render offers a free tier that's perfect for testing.

### Step 1: Prepare Your Repository

1. Initialize git in your project (if not already done):
   ```bash
   cd c:\Users\danil\code\predicted_app
   git init
   git add .
   git commit -m "Initial commit - accident prediction API"
   ```

2. Create a new repository on GitHub:
   - Go to https://github.com/new
   - Name it: `accident-prediction-api`
   - Keep it public or private (your choice)
   - Don't initialize with README (we already have files)
   - Click "Create repository"

3. Push your code to GitHub:
   ```bash
   git remote add origin https://github.com/YOUR_USERNAME/accident-prediction-api.git
   git branch -M main
   git push -u origin main
   ```

### Step 2: Deploy on Render

1. Go to https://render.com and sign up (use your GitHub account)

2. Click "New +" and select "Web Service"

3. Connect your GitHub repository `accident-prediction-api`

4. Configure the service:
   - **Name**: accident-prediction-api
   - **Region**: Choose closest to your location
   - **Branch**: main
   - **Runtime**: Python 3
   - **Build Command**: `pip install -r requirements.txt`
   - **Start Command**: `python api_server.py`
   - **Instance Type**: Free

5. Click "Create Web Service"

6. Wait for deployment (5-10 minutes). Your API will be live at:
   ```
   https://accident-prediction-api-XXXX.onrender.com
   ```

7. Test your API by visiting:
   ```
   https://YOUR_RENDER_URL/api/health
   ```

---

## Option 2: Deploy to Railway (Alternative - Also Free Tier)

1. Go to https://railway.app and sign up with GitHub

2. Click "New Project" → "Deploy from GitHub repo"

3. Select your `accident-prediction-api` repository

4. Railway will auto-detect Python and deploy automatically

5. Click on your service → Settings → Generate Domain

6. Your API will be available at:
   ```
   https://YOUR_APP.up.railway.app
   ```

---

## Option 3: Deploy to PythonAnywhere (Good for Python apps)

1. Sign up at https://www.pythonanywhere.com (free tier available)

2. Go to "Web" tab → "Add a new web app"

3. Choose "Manual configuration" → Python 3.10

4. Upload your files using the "Files" tab or use Git:
   ```bash
   git clone https://github.com/YOUR_USERNAME/accident-prediction-api.git
   ```

5. Set up a virtual environment:
   ```bash
   mkvirtualenv --python=/usr/bin/python3.10 myenv
   pip install -r requirements.txt
   ```

6. Configure the WSGI file to point to your Flask app

7. Reload the web app. Your API will be at:
   ```
   https://YOUR_USERNAME.pythonanywhere.com
   ```

---

## Step 3: Update Your Flutter App

After deploying, you need to update your Flutter app to use the deployed API URL instead of localhost.

### Create API Config File

Create a file `lib/config/api_config.dart`:

```dart
class ApiConfig {
  // PRODUCTION - Replace with your deployed API URL
  static const String baseUrl = 'https://YOUR_RENDER_URL';

  // DEVELOPMENT - Use this for local testing
  // static const String baseUrl = 'http://10.0.2.2:5000'; // Android emulator
  // static const String baseUrl = 'http://localhost:5000'; // iOS simulator

  // API Endpoints
  static const String checkLocation = '$baseUrl/api/check_location';
  static const String safetyTips = '$baseUrl/api/safety_tips';
  static const String alternativeRoutes = '$baseUrl/api/alternative_routes';
  static const String statistics = '$baseUrl/api/statistics';
  static const String barangayList = '$baseUrl/api/barangay_list';
  static const String municipalities = '$baseUrl/api/municipalities';
  static const String barangays = '$baseUrl/api/barangays';
  static const String health = '$baseUrl/api/health';
}
```

### Update Your HTTP Calls

Find all places in your Flutter code where you make API calls and replace the URL with the config:

```dart
import 'package:predicted_app/config/api_config.dart';
import 'package:http/http.dart' as http;

// Before:
// final response = await http.post(Uri.parse('http://localhost:5000/api/check_location'), ...);

// After:
final response = await http.post(
  Uri.parse(ApiConfig.checkLocation),
  headers: {'Content-Type': 'application/json'},
  body: jsonEncode(data),
);
```

---

## Testing Your Deployment

1. **Test the API** using a browser or Postman:
   ```
   GET https://YOUR_DEPLOYED_URL/api/health
   GET https://YOUR_DEPLOYED_URL/api/municipalities
   ```

2. **Test from Flutter**:
   - Update the API config with your deployed URL
   - Run your Flutter app on a real device or emulator
   - Try checking a location - it should work without your computer running

---

## Important Files for Deployment

- `requirements.txt` - Python dependencies
- `Procfile` - Tells the server how to start your app
- `runtime.txt` - Specifies Python version
- `api_server.py` - Your Flask application
- `*.pkl`, `*.json` - Model and data files (must be in the repository)

---

## Troubleshooting

### API Returns 404 or 500 Error
- Check deployment logs on your platform (Render/Railway/PythonAnywhere)
- Ensure all model files (.pkl, .json) are uploaded
- Verify requirements.txt includes all dependencies

### Flutter App Can't Connect
- Check if the API URL is correct in `api_config.dart`
- Test the API URL in a browser first
- Ensure CORS is enabled (already done in api_server.py)
- Check if your phone has internet connection

### Large File Size Issues
- The `.pkl` model file might be too large for free tiers
- Consider using Git LFS for large files:
  ```bash
  git lfs install
  git lfs track "*.pkl"
  git add .gitattributes
  git commit -m "Track large files with LFS"
  ```

---

## Costs

- **Render Free Tier**: Free, but sleeps after 15 min of inactivity (takes ~30s to wake up)
- **Railway Free Tier**: $5 credit/month, no sleep time
- **PythonAnywhere Free Tier**: Always on, limited CPU

For testing purposes, all these options work great!

---

## Next Steps

1. Deploy the API using one of the options above
2. Update your Flutter app with the API configuration
3. Build and test your Flutter app on a real device
4. Share your app with testers

Your app will now work independently without needing your computer!
