# Flutter owner app

Run `flutter create .` inside this directory if the native Android/iOS platform folders are not present, then run `flutter pub get`.

Run with:
`flutter run --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co --dart-define=SUPABASE_ANON_KEY=YOUR_PUBLIC_KEY`

The public/anon key is safe to ship only when Row Level Security is correctly configured. Never use a service-role key here.
