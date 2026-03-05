#!/bin/bash
git clone https://github.com/flutter/flutter.git -b stable --depth 1
./flutter/bin/flutter clean
./flutter/bin/flutter pub get
./flutter/bin/flutter build web --release --dart-define=SUPABASE_URL=$SUPABASE_URL --dart-define=SUPABASE_PUBLISHABLE_KEY=$SUPABASE_PUBLISHABLE_KEY
