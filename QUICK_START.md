# Quick Start - Deploy Your App in 3 Steps

## Step 1: Deploy Your Backend API (15 minutes)

### Using Render (Easiest & Recommended)

1. **Push code to GitHub**:
   ```bash
   cd c:\Users\danil\code\predicted_app
   git init
   git add .
   git commit -m "Initial commit"
   ```

2. **Create GitHub repo** at https://github.com/new
   - Name: `accident-prediction-api`
   - Click "Create repository"

3. **Push to GitHub**:
   ```bash
   git remote add origin https://github.com/YOUR_USERNAME/accident-prediction-api.git
   git branch -M main
   git push -u origin main
   ```

4. **Deploy on Render**:
   - Go to https://render.com
   - Sign up with GitHub
   - Click "New +" → "Web Service"
   - Select your repository
   - Settings:
     - Build: `pip install -r requirements.txt`
     - Start: `python api_server.py`
     - Free instance
   - Click "Create Web Service"
   - Wait 5-10 minutes

5. **Copy your URL**: `https://accident-prediction-api-xxxx.onrender.com`

---

## Step 2: Update Flutter App (5 minutes)

1. **Open** `lib/config/api_config.dart`

2. **Replace** line 10:
   ```dart
   static const String productionUrl = 'https://YOUR_ACTUAL_RENDER_URL_HERE';
   ```

3. **Make sure** line 17 is set to use production:
   ```dart
   static const bool isLocal = false;
   ```

4. **Update your API calls** to use the config:
   ```dart
   // Add this import at the top of your API service files
   import 'package:predicted_app/config/api_config.dart';

   // Use endpoints like this:
   final response = await http.post(
     Uri.parse(ApiConfig.checkLocation),
     headers: {'Content-Type': 'application/json'},
     body: jsonEncode(yourData),
   );
   ```

---

## Step 3: Test Your App (2 minutes)

1. **Test API in browser**: Visit `https://your-url/api/health`

2. **Run Flutter app** on your phone or emulator

3. **Try the features** - they should work without your computer running!

---

## Switching Between Local & Production

In `lib/config/api_config.dart`, change line 17:

```dart
// For production (deployed API)
static const bool isLocal = false;

// For local testing (API running on your computer)
static const bool isLocal = true;
```

---

## Troubleshooting

**API not loading?**
- Check the URL in browser: `https://your-url/api/health`
- Look at Render logs for errors
- Ensure all files (.pkl, .json) are in the repository

**Flutter can't connect?**
- Verify the URL in `api_config.dart`
- Check internet connection on device
- Make sure `isLocal = false`

**Render app sleeping?**
- Free tier sleeps after 15 min inactivity
- First request takes 30s to wake up
- Consider Railway or upgrade to paid tier

---

## Files Created

- `Procfile` - Tells Render how to run your app
- `runtime.txt` - Python version
- `requirements.txt` - Updated with gunicorn
- `api_server.py` - Updated for production
- `lib/config/api_config.dart` - API configuration
- `DEPLOYMENT.md` - Detailed deployment guide

---

## Need Help?

1. Read the full guide: [DEPLOYMENT.md](DEPLOYMENT.md)
2. Check Render documentation: https://render.com/docs
3. Test your API endpoints using Postman or browser

Your app is now ready for testing independently!
