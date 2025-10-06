# Supabase Setup Guide for Increment App

## Phase 1: Initial Setup

### 1. Create Supabase Project

1. Go to [supabase.com](https://supabase.com)
2. Sign up/Login with your account
3. Click "New Project"
4. Choose your organization
5. Enter project details:
   - Name: `increment-app`
   - Database Password: (generate a strong password)
   - Region: Choose closest to your users
6. Click "Create new project"

### 2. Get Your Project Credentials

1. Go to Project Settings → API
2. Copy your:
   - **Project URL** (e.g., `https://your-project.supabase.co`)
   - **Anon Key** (public key, safe to use in client apps)

### 3. Update Configuration

Edit `Models/SupabaseConfig.swift`:
```swift
private let supabaseURL = URL(string: "https://your-project.supabase.co")!
private let supabaseAnonKey = "your-anon-key-here"
```

### 4. Create Database Schema

1. Go to your Supabase project dashboard
2. Navigate to SQL Editor
3. Copy and paste the contents of `supabase_schema.sql`
4. Click "Run" to execute the schema

### 5. Configure Authentication

1. Go to Authentication → Settings
2. Configure Site URL: `increment-app://` (your app's custom URL scheme)
3. Add redirect URLs: `increment-app://` (for OAuth redirects)
4. Enable email confirmations (optional for development)

### 6. Add Supabase to Xcode Project

1. Open your Xcode project
2. Go to File → Add Package Dependencies
3. Enter URL: `https://github.com/supabase/supabase-swift`
4. Click "Add Package"
5. Select all products: Supabase, Auth, Realtime
6. Click "Add Package"

### 7. Test the Setup

1. Build and run your app
2. You should see the authentication screen
3. Try creating an account
4. Check your Supabase dashboard to see the user created

## Phase 2: Data Migration (Coming Next)

Once Phase 1 is working:

1. **Enable Bidirectional Sync**
   - Local data syncs to Supabase
   - Supabase data syncs to local
   - Conflict resolution

2. **Gradual Migration**
   - New data goes to Supabase first
   - Existing data migrates over time
   - Fallback to local storage

3. **Remove Local Storage**
   - All data in Supabase
   - Real-time sync across devices
   - Cloud backup

## Troubleshooting

### Common Issues:

1. **"Connection Failed"**
   - Check your Project URL and Anon Key
   - Ensure your Supabase project is active
   - Check internet connection

2. **"Authentication Failed"**
   - Verify email/password format
   - Check Supabase Authentication settings
   - Ensure email confirmations are disabled for testing

3. **"Database Error"**
   - Verify schema was created correctly
   - Check Row Level Security policies
   - Ensure user is authenticated

### Testing Checklist:

- [ ] Supabase project created
- [ ] Database schema executed
- [ ] Configuration updated with correct credentials
- [ ] Supabase package added to Xcode
- [ ] App builds without errors
- [ ] Authentication screen appears
- [ ] User can sign up
- [ ] User can sign in
- [ ] Sign out works
- [ ] User data appears in Supabase dashboard

## Next Steps

Once Phase 1 is complete:
1. Test authentication thoroughly
2. Verify data isolation between users
3. Implement bidirectional sync
4. Add real-time features
5. Migrate existing local data

## Security Notes

- Never commit your Supabase credentials to version control
- Use environment variables for production
- The anon key is safe for client-side use
- Row Level Security protects user data
- Always validate data on the server side
