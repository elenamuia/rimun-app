# RIMUN App

Flutter client for RIMUN with Firebase auth/notices and FastAPI backend for data.

## Setup

1) Create an environment file:

```
cp .env.example .env
```

Edit `.env` to set your server URL:

```
API_BASE_URL=http://127.0.0.1:8081
```

2) Install dependencies:

```
flutter pub get
```

3) Run the app:

```
flutter run
```

## Backend Contract

See `docs/api-rimun.md` for available endpoints (health, forums, committees, delegates, sessions, posts).

## Quick Check (optional)

You can verify connectivity by calling the service in a widget/init state:

```dart
import 'package:rimun_app/services/rimun_api_service.dart';

final api = RimunApiService();
final ok = await api.isServerHealthy(); // expect true
```

