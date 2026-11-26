@echo off
echo Running flutterfire configure for project lineup-32c58...
echo When prompted, confirm/select the existing app registrations if offered.
echo.
flutterfire configure --project=lineup-32c58 --platforms=android,ios,web,windows
echo.
echo Done. Check above for any errors.
pause
